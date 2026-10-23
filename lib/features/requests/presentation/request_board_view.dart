import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// The "Ask" tab of Rewards: price checks other shoppers need, plus the
/// current user's own requests. Two columns on desktop, one on phones.
class RequestBoardView extends ConsumerWidget {
  const RequestBoardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final requests = ref.watch(priceRequestsProvider);
    final myRequests = ref.watch(myRequestsProvider);
    final requestCost = ref.watch(adminSettingsProvider).requestCostTokens;
    // "Price checks people need" is the COMMUNITY board: only other shoppers'
    // open requests. Exclude the current user's own (they're shown separately
    // under "My Price Requests", and the backend blocks fulfilling your own
    // request anyway).
    final myRequestIds = myRequests.map((r) => r.id).toSet();
    final activeRequests = requests
        .where(
          (r) =>
              (r.status == 'open' || r.status == 'pending') &&
              !myRequestIds.contains(r.id),
        )
        .toList();

    final mine = myRequests.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsSectionHeader('My Price Requests (${myRequests.length})'),
              const SizedBox(height: 8),
              for (final req in myRequests) _MyRequestItemCard(request: req),
            ],
          );

    final community = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(l.requestBoardTitle(activeRequests.length)),
        const SizedBox(height: 8),
        if (activeRequests.isEmpty)
          DsCard(
            padding: EdgeInsets.zero,
            child: DsEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: l.requestEmptyTitle,
              message: l.requestEmptySubtitle,
            ),
          )
        else
          for (final req in activeRequests) _RequestItemCard(request: req),
      ],
    );

    final ask = DsButton(
      label: l.requestAskForPrice,
      icon: Icons.add_comment_rounded,
      onPressed: () => _showRequestFormSheet(context, ref, requestCost),
    );

    final banner = DsBanner(
      l.requestBannerExplanation,
      tone: DsBannerTone.warn,
      icon: Icons.help_center_rounded,
    );

    if (context.isExpanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                banner,
                const SizedBox(height: 16),
                ask,
                if (mine != null) ...[const SizedBox(height: 24), mine],
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: community),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: 16),
        ask,
        if (mine != null) ...[const SizedBox(height: 24), mine],
        const SizedBox(height: 24),
        community,
      ],
    );
  }

  void _showRequestFormSheet(
    BuildContext context,
    WidgetRef ref,
    int requestCost,
  ) {
    final l = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    String productName = '';
    String selectedStore = 'Carrefour';

    final List<String> stores = [
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

    // Hide navbar when sheet opens
    ref.read(navbarVisibleProvider.notifier).hide();

    InputDecoration deco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: AppFonts.body(fontSize: 16, color: AppTheme.textLight),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.forestDeep, width: 2),
      ),
    );

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.requestFormTitle,
                  style: AppFonts.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.requestFormSubtitle(requestCost),
                  style: AppFonts.body(
                    color: AppTheme.textLight,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: deco(
                    l.requestItemNameLabel,
                    hint: l.requestItemNameHint,
                  ),
                  style: AppFonts.body(fontSize: 17, color: AppTheme.ink),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l.requestItemNameValidation;
                    }
                    return null;
                  },
                  onSaved: (val) => productName = val!.trim(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStore,
                  isExpanded: true,
                  decoration: deco(l.requestStoreLabel),
                  items: stores.map((s) {
                    return DropdownMenuItem<String>(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) => selectedStore = val!,
                ),
                const SizedBox(height: 24),
                DsButton(
                  label: l.requestSubmitButton,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final notifier = ref.read(myRequestsProvider.notifier);
                      final messenger = ScaffoldMessenger.of(context);
                      await notifier.addPriceRequest(
                        productName: productName,
                        storeName: selectedStore,
                        requestCostTokens: requestCost,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      final err = notifier.lastError;
                      if (err != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: AppTheme.badText,
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.good,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(l.requestSentTitle)),
                              ],
                            ),
                            content: Text(
                              l.requestSentBody(
                                productName,
                                selectedStore,
                                requestCost,
                              ),
                              style: AppFonts.body(fontSize: 16, height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l.requestSentConfirm),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Restore navbar when sheet is dismissed by any means
      ref.read(navbarVisibleProvider.notifier).show();
    });
  }
}

class _RequestItemCard extends StatelessWidget {
  final PriceRequest request;

  const _RequestItemCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.limeAccent.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_center_outlined,
                    color: AppTheme.forestDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.requestCardSubtitle(
                          request.storeName,
                          request.requesterName,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          color: AppTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DsButton(
              label: l.requestCheckPriceButton(request.requestRewardTokens),
              compact: true,
              onPressed: () {
                // Navigate to submit price prefilled
                context.push(
                  '/submit-price',
                  extra: {
                    'requestId': request.id,
                    'productName': request.productName,
                    'storeName': request.storeName,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRequestItemCard extends ConsumerWidget {
  final PriceRequest request;

  const _MyRequestItemCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tone = request.status == 'fulfilled'
        ? DsTone.good
        : request.status == 'refunded'
        ? DsTone.teal
        : request.status == 'open'
        ? DsTone.warn
        : DsTone.neutral;

    final displayStatus = request.status == 'open'
        ? 'PENDING'
        : request.status == 'fulfilled'
        ? 'ACCEPTED'
        : request.status.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DsCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${request.storeName} • ${request.timestampLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      color: AppTheme.textLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DsTag(displayStatus, tone: tone),
                ],
              ),
            ),
            if (request.status == 'open')
              IconButton(
                tooltip: l.profileCancelRequest,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: AppTheme.redAccent,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text(l.profileCancelRequestTitle),
                      content: Text(
                        l.profileCancelRequestBody(request.productName),
                        style: AppFonts.body(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l.profileNo),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(myRequestsProvider.notifier)
                                .cancelRequest(request.id);
                            Navigator.pop(context);
                          },
                          child: Text(
                            l.profileYesCancel,
                            style: const TextStyle(color: AppTheme.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
