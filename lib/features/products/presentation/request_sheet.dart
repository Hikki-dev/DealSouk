import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

const _requestStores = [
  'Carrefour',
  'Lulu Hypermarket',
  'Spinneys',
  'Union Coop',
  'Nesto',
  'Choithrams',
  'Grandiose',
  'Waitrose',
  'Al Maya',
  'Geant',
  'Al Madina',
];

/// Bottom sheet that lets a shopper ask the community to check a price.
/// Prefilled with what they typed. Shared by Home and Search.
Future<void> showItemRequestSheet(
  BuildContext context,
  WidgetRef ref,
  String initialQuery,
  int requestCost, {
  VoidCallback? onDone,
}) {
  final formKey = GlobalKey<FormState>();
  var productName = initialQuery;
  var selectedStore = _requestStores.first;

  ref.read(navbarVisibleProvider.notifier).hide();

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.searchRequestPriceCheckTitle,
                  style: AppFonts.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.searchRequestPriceCheckDescription(requestCost),
                  style: AppFonts.body(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  initialValue: productName,
                  decoration: InputDecoration(
                    labelText: l.searchItemNameLabel,
                    hintText: l.searchItemNameHint,
                  ),
                  onChanged: (val) => productName = val,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? l.searchEnterProductName
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStore,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.searchChooseSupermarket,
                  ),
                  items: [
                    for (final s in _requestStores)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedStore = val;
                  },
                ),
                const SizedBox(height: 24),
                DsButton(
                  label: l.searchAskForThisPrice,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final notifier = ref.read(myRequestsProvider.notifier);
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.addPriceRequest(
                      productName: productName.trim(),
                      storeName: selectedStore,
                      requestCostTokens: requestCost,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    final err = notifier.lastError;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(err ?? l.searchRequestPosted),
                        backgroundColor: err != null
                            ? AppTheme.badText
                            : AppTheme.forestDeep,
                      ),
                    );
                    if (err == null) onDone?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    ref.read(navbarVisibleProvider.notifier).show();
  });
}
