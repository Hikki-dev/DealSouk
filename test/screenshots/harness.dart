import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/core/offline/connectivity_service.dart';
import 'package:dealsouk/core/offline/sync_service.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// Screen sizes used across the screenshot tests (logical pixels).
class Sizes {
  static const phone = Size(390, 844);
  static const tablet = Size(820, 1180);
  static const desktop = Size(1440, 900);
}

bool _fontsLoaded = false;

/// Loads the bundled Readex Pro and the Material icon font so screenshots show
/// real text and icons instead of test placeholder boxes.
Future<void> loadFonts() async {
  if (_fontsLoaded) return;
  final app = FontLoader('ReadexPro');
  for (final w in [400, 500, 600, 700]) {
    final bytes = File('assets/fonts/ReadexPro-$w.ttf').readAsBytesSync();
    app.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await app.load();

  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Providers that would otherwise reach for plugins or the network.
List<Override> baseOverrides() => [
  isOnlineProvider.overrideWithValue(true),
  syncControllerProvider.overrideWith(_FakeSync.new),
];

class _FakeSync extends SyncController {
  @override
  int build() => 0;
}

/// Renders [screen] at [size] and writes a PNG to `build/screenshots/[name]`.
///
/// Rendering overflow or any widget exception fails the test, so these double
/// as layout smoke tests.
Future<void> shoot(
  WidgetTester tester,
  Widget screen, {
  required String name,
  Size size = Sizes.phone,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  List<Override> overrides = const [],
  double pixelRatio = 1.5,
  Duration settle = const Duration(milliseconds: 600),
}) async {
  await loadFonts();
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...baseOverrides(), ...overrides],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: screen,
        ),
      ),
    ),
  );

  // Let bundled images decode, then settle layout.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump(settle);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump(settle);

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/screenshots/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// A signed-out auth notifier that never touches Firebase.
class FakeAuth extends AuthNotifier {
  FakeAuth([this._state = const AuthState(status: AuthStatus.unauthenticated)]);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

Override fakeAuth([AuthState? state]) => authProvider.overrideWith(
  () => state == null ? FakeAuth() : FakeAuth(state),
);
