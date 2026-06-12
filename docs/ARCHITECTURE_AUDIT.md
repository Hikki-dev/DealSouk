# DealSouk Architecture Audit

**Date**: June 12, 2026  
**Auditor**: Antigravity AI  
**Repository Branch**: `feature/flutter-api-integration`

---

## 1. Executive Summary

This architecture audit evaluates the structural design of the DealSouk Flutter client. While the application is functional and integrates successfully with the Node.js backend, Firebase Auth, and Neon Postgres, its architecture suffers from severe coupling, centralization bottlenecks, and violations of separation of concerns.

The primary issue is the concentration of application state and business logic in the monolithic [state.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/state/state.dart) file, as well as domain models in [models.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/models/models.dart). To ensure maintainability, scalability, and clean boundaries for future development, we must transition to a feature-driven clean architecture.

---

## 2. Analysis of Current Bottlenecks

### 2.1 The Centralized State Bottleneck (`state.dart`)
The file [state.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/state/state.dart) is a 764-line monolithic file containing:
- 12 distinct `Notifier` classes (representing products, cart, profile, leaderboard, tokens, transactions, flagged prices, price requests, streaks, badges, daily challenges, and admin settings).
- 18 separate global Riverpod provider variables.
- Direct dependencies on 8 distinct API services from `lib/core/services/`.
- Utility functions for level conversions (`tokensToLevel`, `levelTitle`, etc.).

**Consequences**:
- **Lack of Encapsulation**: Any change to one feature (e.g. changing admin settings properties) alters `state.dart`, forcing compilation checks on all 13 screens/widgets that import it.
- **Merge Conflicts**: Multiple developers working on different features (like cart optimization and daily challenges) will constantly clash in this file.
- **Testing Difficulties**: Mocking or isolating specific feature state during widget tests is difficult because states are highly coupled.

### 2.2 Monolithic Domain Models (`models.dart`)
The file [models.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/models/models.dart) is a 506-line monolithic file containing definitions for:
- `Product`, `Store`, `StoreProductPrice`, `CartItem`, `LeaderboardUser`, `TokenTransaction`, `AdminSubmission`, `PriceRequest`, `StreakData`, `UserBadge`, `DailyChallenge`, and `AdminSettings`.

**Consequences**:
- Domain models from independent bounded contexts (e.g. `Product` catalog vs `TokenTransaction` economy) are coupled together.
- Adding a property to `AdminSubmission` modifies the same file containing the core `Product` model.

### 2.3 UI & Business Logic Co-location (Large Screen Files)
Several screen files are extremely large and contain non-UI logic (e.g., API calling triggers, dialog builders, sorting algorithms, and calculations):
- `admin_screen.dart` (2,386 lines)
- `home_screen.dart` (1,383 lines)
- `leaderboard_screen.dart` (1,272 lines)
- `cart_screen.dart` (1,005 lines)
- `product_detail_screen.dart` (818 lines)
- `welcome_screen.dart` (802 lines)

**Consequences**:
- Hard to navigate, maintain, or refactor.
- Changes to layout properties can easily introduce regressions in data handling or workflow logic.

---

## 3. Recommended Clean Architecture Targets

We will restructure the application by adopting a clean, feature-driven architecture that separates concerns into three key layers for each feature module:
1. **Data Layer (`data/`)**: API services, Dio client calls, and cache datasources.
2. **Domain Layer (`domain/`)**: Pure business logic, entity models, and value objects.
3. **Presentation Layer (`presentation/`)**: Widgets, pages, and feature-specific Riverpod providers/controllers.

```text
lib/
  app/                     # Core application bootstrap and routing
    app.dart
    router.dart
    bootstrap.dart
  core/                    # Shared infrastructure across all features
    config/                # App config & environment variables
    theme/                 # Styling colors, typography, shapes
    localization/          # ARB translation delegates and locales
    widgets/               # Shared reusable custom UI components
    network/               # HTTP client client, interceptors
    errors/                # Standardized exception and error handling
    utils/                 # DateTime formatting, geolocation helpers
  features/                # Bounded feature modules
    auth/                  # OTP registration, Google & Apple Sign-In
    products/              # Search, categories, price history charts
    stores/                # Google Maps, radius discoverability
    cart/                  # Cart notifier, basket comparison engine
    submissions/           # Image capturing, manual price forms
    requests/              # Request boards, bounty token transfers
    tokens/                # Economy, streak history, daily challenges
    leaderboard/           # Monthly rank scoring, Hall of Fame
    profile/               # Home areas, locale, PII deletion
    admin/                 # Moderation queues, system configuration settings
```

By decoupling features, we enable:
- **Clean Boundaries**: Feature code is completely self-contained.
- **Easy Maintenance**: Modifying a screen only touches that feature directory.
- **Testability**: Independent unit/widget tests can be written for each folder.
- **Scale**: Multiple developers can work concurrently without conflicts.
