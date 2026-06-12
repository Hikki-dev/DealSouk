# DealSouk Refactoring Plan

**Goal**: Refactor the DealSouk Flutter client to transition from a coupled centralized structure into a clean, feature-driven architecture. 

We will execute this plan using a sequence of **small, compile-validated commits** to ensure we never break the build or functionality.

---

## 1. File Movement Mapping

| Original File | Target Location | Feature/Component |
|---|---|---|
| `lib/app.dart` | [app.dart](file:///Users/hikki/Desktop/DealSouk/lib/app/app.dart) | Shell / Router configuration |
| `lib/core/router/router.dart` | [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/app/router.dart) | Navigation and Auth guards |
| *New File* | [bootstrap.dart](file:///Users/hikki/Desktop/DealSouk/lib/app/bootstrap.dart) | Firebase/app initialization routines |
| `lib/core/services/api_client.dart` | [api_client.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/network/api_client.dart) | Core Networking layer |
| `lib/core/services/storage_service.dart` | [storage_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/network/storage_service.dart) | Firebase Storage operations |
| `lib/core/services/fcm_service.dart` | [fcm_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/network/fcm_service.dart) | Messaging infrastructure |
| `lib/core/services/auth_service.dart` | [auth_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/data/auth_service.dart) | Authentication APIs |
| `lib/core/state/auth_provider.dart` | [auth_providers.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/presentation/auth_providers.dart) | Auth State and providers |
| `lib/features/auth/welcome_screen.dart` | [welcome_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/presentation/welcome_screen.dart) | Login UI Screen |
| `lib/core/services/products_service.dart` | [products_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/data/products_service.dart) | Product discovery APIs |
| `lib/features/products/search_screen.dart` | [search_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/presentation/search_screen.dart) | Product Search Screen |
| `lib/features/products/product_detail_screen.dart` | [product_detail_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/presentation/product_detail_screen.dart) | Product details |
| `lib/core/services/stores_service.dart` | [stores_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/data/stores_service.dart) | Store Discovery APIs |
| `lib/features/stores/store_screen.dart` | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/presentation/store_screen.dart) | Supermarkets & Maps UI |
| `lib/features/cart/cart_screen.dart` | [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/presentation/cart_screen.dart) | Grocery basket comparison |
| `lib/core/services/submissions_service.dart` | [submissions_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/data/submissions_service.dart) | Price submission APIs |
| `lib/features/submissions/submit_price_screen.dart` | [submit_price_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/presentation/submit_price_screen.dart) | Submit price form UI |
| `lib/core/services/requests_service.dart` | [requests_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/requests/data/requests_service.dart) | Item Request APIs |
| `lib/features/leaderboard/request_board_view.dart` | [request_board_view.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/requests/presentation/request_board_view.dart) | Request list and bounty UI |
| `lib/core/services/leaderboard_service.dart` | [leaderboard_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/data/leaderboard_service.dart) | Monthly rank board APIs |
| `lib/features/leaderboard/leaderboard_screen.dart` | [leaderboard_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/presentation/leaderboard_screen.dart) | Leaderboard list UI |
| `lib/core/services/profile_service.dart` | [profile_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/data/profile_service.dart) | Profile & Settings APIs |
| `lib/features/profile/profile_screen.dart` | [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/presentation/profile_screen.dart) | Settings & streaks UI |
| `lib/core/services/admin_service.dart` | [admin_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/data/admin_service.dart) | Admin queue/settings APIs |
| `lib/features/admin/admin_screen.dart` | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/presentation/admin_screen.dart) | Moderation dashboard UI |
| `lib/features/admin/admin_app.dart` | [admin_app.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/presentation/admin_app.dart) | Admin web application |
| `lib/features/home/home_screen.dart` | [home_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/home/presentation/home_screen.dart) | Core Home Feed Screen |

---

## 2. Refactoring Sequence (Commit-by-Commit)

### Phase 1: App & Core Infrastructure Setup
- **Commit 1**: Create `lib/app/bootstrap.dart` containing app initializers. Move `lib/app.dart` to `lib/app/app.dart`, and `lib/core/router/router.dart` to `lib/app/router.dart`. Update all imports in `main.dart` and the router.
- **Commit 2**: Move `lib/core/services/api_client.dart` to `lib/core/network/api_client.dart`. Update imports.
- **Commit 3**: Move `lib/core/services/storage_service.dart` and `fcm_service.dart` to `lib/core/network/`.

### Phase 2: Decouple Models (`lib/core/models/models.dart`)
- **Commit 4**: Move `Product` and `StoreProductPrice` to `lib/features/products/domain/product.dart` and `lib/features/products/domain/store_product_price.dart`.
- **Commit 5**: Move `Store` to `lib/features/stores/domain/store.dart`.
- **Commit 6**: Move `CartItem` to `lib/features/cart/domain/cart_item.dart`.
- **Commit 7**: Move `LeaderboardUser` to `lib/features/leaderboard/domain/leaderboard_user.dart`.
- **Commit 8**: Move `AdminSubmission` and `AdminSettings` to `lib/features/admin/domain/admin_submission.dart` and `admin_settings.dart`.
- **Commit 9**: Move `PriceRequest` to `lib/features/requests/domain/price_request.dart`.
- **Commit 10**: Move `TokenTransaction`, `StreakData`, `UserBadge`, and `DailyChallenge` to `lib/features/tokens/domain/` (or `profile/` where appropriate).
- **Commit 11**: Remove `lib/core/models/models.dart` and update all client imports to target domain-level files.

### Phase 3: Split Monolithic State (`state.dart` & `auth_provider.dart`)
- **Commit 12**: Move `authProvider` to `lib/features/auth/presentation/auth_providers.dart`.
- **Commit 13**: Extract `productsProvider`, `filterProvider`, and `flaggedPricesProvider` to `lib/features/products/presentation/products_providers.dart`.
- **Commit 14**: Extract `storesProvider` to `lib/features/stores/presentation/stores_providers.dart`.
- **Commit 15**: Extract `cartProvider` to `lib/features/cart/presentation/cart_providers.dart`.
- **Commit 16**: Extract `priceRequestsProvider` to `lib/features/requests/presentation/requests_providers.dart`.
- **Commit 17**: Extract `leaderboardProvider` to `lib/features/leaderboard/presentation/leaderboard_providers.dart`.
- **Commit 18**: Extract token/gamification providers (`userTokensProvider`, `userTransactionsProvider`, `streakProvider`, `badgesProvider`, `dailyChallengeProvider`) to `lib/features/tokens/presentation/tokens_providers.dart`.
- **Commit 19**: Extract `userProfileProvider` and `navbarVisibleProvider` to `lib/features/profile/presentation/profile_providers.dart`.
- **Commit 20**: Extract `adminSubmissionsProvider` and `adminSettingsProvider` to `lib/features/admin/presentation/admin_providers.dart`.
- **Commit 21**: Extract `localeProvider` to `lib/core/localization/locale_provider.dart`.
- **Commit 22**: Delete `lib/core/state/state.dart` and `auth_provider.dart`. Update remaining code imports.

### Phase 4: Move UI Screens
- **Commit 23**: Move `lib/features/auth/welcome_screen.dart` to `lib/features/auth/presentation/welcome_screen.dart`.
- **Commit 24**: Move product screen files to `lib/features/products/presentation/`.
- **Commit 25**: Move store screen files to `lib/features/stores/presentation/`.
- **Commit 26**: Move cart screen files to `lib/features/cart/presentation/`.
- **Commit 27**: Move submission screen files to `lib/features/submissions/presentation/`.
- **Commit 28**: Move request and leaderboard screen files to respective `presentation/` subfolders.
- **Commit 29**: Move profile and admin screen files to respective `presentation/` subfolders.
- **Commit 30**: Move `lib/features/home/home_screen.dart` to `lib/features/home/presentation/home_screen.dart`.

### Phase 5: Move Service Files
- **Commit 31**: Move feature API services (`auth_service.dart`, `products_service.dart`, etc.) to respective `features/*/data/` folders.
- **Commit 32**: Clean up empty directories, format the codebase (`dart format .`), verify static analysis (`flutter analyze`), and compile.

---

## 3. Validation Gates

After **every single commit**, the following checks must pass:
1. `flutter analyze` — Must return no errors or warnings.
2. `flutter build web --dart-define=ADMIN_MODE=true` (or compilation tests) to ensure the admin application compiles.
3. No untracked files left in legacy locations.
