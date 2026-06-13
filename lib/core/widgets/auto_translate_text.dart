import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/localization/locale_provider.dart';
import 'package:dealsouk/core/services/translation_service.dart';

/// Wraps a [Text] widget and auto-translates its content when the app locale
/// differs from 'en'. Used for user-generated content (product names, store
/// names, request descriptions) that isn't covered by static .arb keys.
///
/// Renders the original text immediately, then swaps in the translation once
/// the async call resolves. Falls back silently to the original on any error.
class AutoTranslateText extends ConsumerWidget {
  const AutoTranslateText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    if (locale.languageCode == 'en' || text.isEmpty) {
      return _plain(text);
    }
    return _AsyncTranslateText(
      text: text,
      target: locale.languageCode,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }

  Widget _plain(String t) => Text(
    t,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
    softWrap: softWrap ?? true,
  );
}

class _AsyncTranslateText extends ConsumerStatefulWidget {
  const _AsyncTranslateText({
    required this.text,
    required this.target,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  final String text;
  final String target;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  ConsumerState<_AsyncTranslateText> createState() =>
      _AsyncTranslateTextState();
}

class _AsyncTranslateTextState extends ConsumerState<_AsyncTranslateText> {
  String? _translated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AsyncTranslateText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.target != widget.target) _load();
  }

  Future<void> _load() async {
    final service = ref.read(translationServiceProvider);
    final result = await service.translate(widget.text, widget.target);
    if (mounted) setState(() => _translated = result);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translated ?? widget.text,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
      softWrap: widget.softWrap ?? true,
    );
  }
}
