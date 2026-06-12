# DealSouk Architecture Audit

Date: 2026-06-12
Branch audited: `feature/flutter-api-integration`

## Executive Summary

The major architecture refactor has largely been completed. The old centralized layout with `lib/core/state/state.dart`, `lib/core/models/models.dart`, `lib/core/services/*`, and flat `lib/features/*/*.dart` screens has been moved into a feature-first structure:

```text
lib/
  app/
  core/
    localization/
    network/
    theme/
    widgets/
  features/
    admin/{data,domain,presentation}
    auth/{data,domain,presentation}
    cart/{domain,presentation}
    home/presentation
    leaderboard/{data,domain,presentation}
    products/{data,domain,presentation}
    profile/{data,presentation}
    requests/{data,domain,presentation}
    stores/{data,domain,presentation}
    submissions/{data,presentation}
    tokens/{data,domain,presentation}
```

This is a strong improvement: Riverpod providers are now feature-scoped, domain models are no longer bundled in one global model file, and service classes mostly live beside the features that consume them.

## What Is Done

| Area | Status | Evidence |
|---|---|---|
| App shell split | Done | `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/bootstrap.dart` |
| Auth state split | Done | `lib/features/auth/presentation/auth_providers.dart` |
| Feature providers split | Done | `lib/features/products/presentation/products_providers.dart`, `lib/features/cart/presentation/cart_providers.dart`, `lib/features/tokens/presentation/tokens_providers.dart` |
| Domain models split | Done | `lib/features/products/domain/product.dart`, `lib/features/admin/domain/admin_submission.dart`, `lib/features/requests/domain/price_request.dart` |
| Network layer moved | Done | `lib/core/network/api_client.dart`, `lib/core/network/storage_service.dart`, `lib/core/network/fcm_service.dart` |
| Localization provider moved | Done | `lib/core/localization/locale_provider.dart` |
| Admin route guard separated | Done | `lib/app/route_guard.dart`, `test/app/route_guard_test.dart` |

## Remaining Architecture Issues

| Issue | Impact | Evidence | Priority | Recommendation |
|---|---|---|---|---|
| Large presentation files still contain too much UI and workflow logic | Hard to test and change safely | `lib/features/admin/presentation/admin_screen.dart`, `lib/features/home/presentation/home_screen.dart`, `lib/features/submissions/presentation/submit_price_screen.dart` | High | Extract small widgets and feature controllers incrementally. |
| Some production providers retain demo fallback data | Production can silently show seeded data when API fails | `lib/features/stores/presentation/stores_providers.dart`, `lib/features/stores/data/dubai_stores_seed.dart` | High | Move fallback data to a mock repository or dev-only provider override. |
| Data layer uses concrete singleton services | Harder to test and swap mock/backend sources | `final productsService = ProductsService()` style files | Medium | Introduce provider-wrapped service instances before adding abstract repositories. |
| Profile model is still in data layer | Domain/presentation boundary is fuzzy | `lib/features/profile/data/profile_service.dart` | Medium | Move `ProfileData`/profile entity to `profile/domain/` when next touched. |
| Core folders are incomplete | Target structure includes `config`, `security`, `errors`, `utils` | `lib/core/` | Low | Add only when real shared code exists. Avoid empty architecture folders. |

## Architecture Quality

Current quality: **Good for MVP, needs cleanup before scale**.

The refactor achieved the important boundary split without over-engineering. The next work should focus on reducing screen-file size, making mock/dev data explicit, and adding provider-based seams for service tests.
