# DealSouk UX Polish Report

Date: 2026-06-12
Goal: make DealSouk feel premium, simple, fast, and trustworthy for non-technical grocery shoppers in Dubai.

## Summary

Applied a narrow UX polish pass focused on clarity, trust, savings, and next actions. This pass intentionally avoided heavy redesign, unnecessary animations, and UI snapshot testing.

## Changes Applied

| Area | Change | Files |
|---|---|---|
| Home screen | Improved empty-state copy so users know what to do next; added a direct "Find an item" action. Refined promo carousel copy around fresh nearby prices and saving trips. | `lib/features/home/presentation/home_screen.dart` |
| Price cards/details | Replaced vague missing-comparison text with a clearer trust/action message. Simplified report feedback so users understand hidden prices are reviewed. | `lib/features/products/presentation/product_detail_screen.dart` |
| Search/request flow | Changed "Request this price (+15 Tokens)" and "Post Request" style copy into simpler shopper language: "Ask shoppers to check" and "Ask for this price". | `lib/features/products/presentation/search_screen.dart` |
| Submit price flow | Shortened "Enter Price details" to "Enter Price"; changed final CTA to "Submit a price"; stopped showing optimistic success if backend submission fails. | `lib/features/submissions/presentation/submit_price_screen.dart` |
| Request board | Replaced persona-specific requester name with generic "Shopper"; improved success dialog language. | `lib/features/requests/presentation/request_board_view.dart` |
| Profile/settings | Improved empty states for submissions, token history, and requests so users know the next useful action. | `lib/features/profile/presentation/profile_screen.dart` |
| Arabic/English polish | Changed "Sourcer Badges" to "Shopper Badges" in English and Arabic localization files. | `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, generated localization Dart files |

## Screen Checklist

| Screen | What can I do here? | How does this save money? | Can I trust this price? | What should I tap next? | Status |
|---|---|---|---|---|---|
| Home | Browse fresh nearby prices and jump into search/request flows. | Promo copy and empty state now emphasize nearby prices before leaving home. | Freshness/filter context is clearer. | "Find an item" in empty state. | Improved |
| Price details/cards | Compare stores and save prices. | Missing comparison state now pushes users to request a check. | Report feedback explains review/hide behavior. | Save price or request/check price. | Improved |
| Cart/My List | Compare saved prices by store. | Existing best-store banner already explains cheapest/closest tradeoff. | Still needs stronger verified/fresh labels per saved item. | Add more items or clear list. | Partial |
| Submit price | Share a shelf price. | Users see tokens as reward, not cash value. | Failed backend submissions no longer look successful. | "Submit a price". | Improved |
| Request price | Ask shoppers for a price check. | Users can get a shelf price before traveling. | Language now avoids fake/persona-specific requesters. | "Ask for this price". | Improved |
| Token/leaderboard | See rewards, rank, and challenges. | Shopper badges language is less technical. | Still needs deeper copy pass for voucher/token rules. | Check challenge/request board. | Partial |
| Profile/settings | Review submissions, tokens, requests, and settings. | Empty states explain how to earn and request. | Admin shortcut remains hidden for non-admins. | Share a price or ask for a price. | Improved |
| Loading states | Existing loading indicators remain. | Not directly applicable. | Needs clearer loading copy in some screens. | Wait/retry. | Partial |
| Error messages | Submission failure now tells users to check connection and retry. | Prevents false confidence. | Trust improved by avoiding fake success. | Retry submit. | Improved |

## Remaining UX Work

1. Add consistent trust chips to every price card: freshness, distance, and photo verification.
2. Add clearer loading labels where screens currently show only spinners.
3. Add friendly retry actions for API-backed empty/error states.
4. Ensure request creation uses the production token-cost rule everywhere before release.
5. Run a full Arabic RTL device pass, not just localization string checks.

## Validation

Commands run after changes:

```sh
flutter analyze
flutter test
```

Results:

- `flutter analyze`: passed.
- `flutter test`: passed, 13 tests.
