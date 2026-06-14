import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

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
    // under "My Price Requests" above, and the backend blocks fulfilling your
    // own request anyway).
    final myRequestIds = myRequests.map((r) => r.id).toSet();
    final activeRequests = requests
        .where(
          (r) =>
              (r.status == 'open' || r.status == 'pending') &&
              !myRequestIds.contains(r.id),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner explanation
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFECB3), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.help_center_rounded,
                  color: AppTheme.amberAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.requestBannerExplanation,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (myRequests.isNotEmpty) ...[
            Text(
              'My Price Requests (${myRequests.length})',
              style: GoogleFonts.fredoka(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestDeep,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myRequests.length,
              itemBuilder: (context, index) {
                final req = myRequests[index];
                return _MyRequestItemCard(request: req);
              },
            ),
            const SizedBox(height: 20),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l.requestBoardTitle(activeRequests.length),
                  style: GoogleFonts.fredoka(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    _showRequestFormSheet(context, ref, requestCost),
                icon: const Icon(Icons.add_comment_rounded, size: 16),
                label: Text(l.requestAskForPrice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activeRequests.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.requestEmptyTitle,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.requestEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.grey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeRequests.length,
              itemBuilder: (context, index) {
                final req = activeRequests[index];
                return _RequestItemCard(request: req);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
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

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.requestFormTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.requestFormSubtitle(requestCost),
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Product Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l.requestItemNameLabel,
                    hintText: l.requestItemNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.forestDeep),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l.requestItemNameValidation;
                    }
                    return null;
                  },
                  onSaved: (val) => productName = val!.trim(),
                ),
                const SizedBox(height: 18),

                // Store Selection
                DropdownButtonFormField<String>(
                  initialValue: selectedStore,
                  decoration: InputDecoration(
                    labelText: l.requestStoreLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: stores.map((s) {
                    return DropdownMenuItem<String>(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) => selectedStore = val!,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
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
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(l.requestSentTitle),
                              ],
                            ),
                            content: Text(
                              l.requestSentBody(
                                productName,
                                selectedStore,
                                requestCost,
                              ),
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.bold,
                              ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l.requestSubmitButton),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.limeAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_center_outlined,
              color: AppTheme.forestDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.requestCardSubtitle(
                    request.storeName,
                    request.requesterName,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.forestDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l.requestCheckPriceButton(request.requestRewardTokens),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
    final statusColor = request.status == 'fulfilled'
        ? Colors.green
        : request.status == 'refunded'
        ? Colors.blue
        : request.status == 'open'
        ? Colors.orange
        : Colors.grey;

    final displayStatus = request.status == 'open'
        ? 'PENDING'
        : request.status == 'fulfilled'
        ? 'ACCEPTED'
        : request.status.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${request.storeName} • ${request.timestampLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (request.status == 'open') ...[
                IconButton(
                  tooltip: l.profileCancelRequest,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppTheme.redAccent,
                    size: 20,
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
                          style: const TextStyle(fontSize: 14),
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
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
