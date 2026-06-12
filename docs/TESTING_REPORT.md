# DealSouk Testing Report

Date: 2026-06-12  
Focus: production business logic, not UI snapshots.

## Summary

Added readable, seeded business-logic tests under:

- `test/cart/`
- `test/tokens/`
- `test/submissions/`
- `test/moderation/`
- `test/localization/`

Existing admin-route guard tests remain under `test/app/`.

## Tests Added

| Requirement Protected | Test File | What It Verifies |
|---|---|---|
| Cart best-price calculation | `test/cart/cart_pricing_test.dart` | Calculates the cheapest complete basket across stores and ignores stores missing cart items. |
| 72-hour price expiry | `test/submissions/price_expiry_test.dart` | Keeps prices fresher than 72 hours and filters out prices at/after the expiry boundary. |
| Token deduction when creating request | `test/tokens/request_token_flow_test.dart` | Deducts request bounty/cost tokens immediately. |
| Token refund when request expires | `test/tokens/request_token_flow_test.dart` | Refunds the same bounty when an unfulfilled request expires. |
| Token reward after approved submission | `test/tokens/request_token_flow_test.dart` | Credits tokens only through the approved-submission reward path. |
| Daily submission cap | `test/tokens/request_token_flow_test.dart` | Blocks submissions once today’s count reaches the configured cap. |
| Flag count auto-hide | `test/moderation/submission_moderation_test.dart` | Counts unique flags only and hides after the third unique flag. |
| Admin approve/reject submission | `test/moderation/submission_moderation_test.dart` | Transitions pending submissions to approved/rejected states. |
| Leaderboard ranking calculation | `test/tokens/leaderboard_ranking_test.dart` | Sorts monthly token totals descending with deterministic tie ordering. |
| Arabic locale smoke test | `test/localization/arabic_locale_smoke_test.dart` | Confirms core Arabic labels are present and not empty/English-only. |

## Pure Helpers Added

| Helper | Purpose |
|---|---|
| `lib/features/cart/domain/cart_pricing.dart` | Basket total and cheapest-store calculation. |
| `lib/features/products/domain/price_freshness.dart` | 72-hour freshness rule. |
| `lib/features/tokens/domain/token_rules.dart` | Token deduction, refund, reward, and daily cap rules. |
| `lib/features/submissions/domain/submission_moderation.dart` | Unique flag counting and moderation status transitions. |
| `lib/features/leaderboard/domain/leaderboard_ranking.dart` | Monthly ranking calculation. |

## Validation

Commands run:

```sh
flutter analyze
flutter test
```

Result:

- `flutter analyze`: passed, no issues.
- `flutter test`: passed, 13 tests total.

## Remaining Test Gaps

- Backend route integration tests for `/requests`, `/submissions`, `/admin`, and `/leaderboard`.
- Storage upload tests for receipt/shelf photo paths and Firebase Storage rules.
- End-to-end auth tests with Firebase emulator/custom claims.
- Widget tests for critical empty/loading/error states after UX polish.
- RTL layout smoke tests beyond localization string checks.
