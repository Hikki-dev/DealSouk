# PRD §10 UI/UX Conformance Audit

Status of the §10 key-screen requirements against the current build. ✅ met ·
🟡 partial / verify · ⬜ gap.

| Req | Requirement | Status | Notes |
|-----|-------------|--------|-------|
| Nav | Bottom tab bar, 5 items (Home/Map/Cart/Leaderboard/Profile), ≤3 levels deep | ✅ | `router.dart` ShellRoute has the five tabs. |
| UI-01 | Home feed defaults to recency; persistent freshness filter chips (All / <6h / <24h / <72h) | ✅ | `home_screen` freshness filter + recency sort (now numeric `hoursAgo`, B5). |
| UI-02 | Cart row: item, qty stepper, best-price badge (store + AED), secondary "Also at" next-cheapest | 🟡 | Cart shows best price + qty; **verify the "Also at" secondary line** is present for each item. |
| UI-03 | Token balance widget count-up animation on earn | 🟡 | Balance shown; **count-up animation not confirmed** — candidate small enhancement. |
| UI-04 | Submission form live token estimate as fields fill | ✅ | `submit_price_screen` live estimate (FR-33). |
| UI-05 | All prices AED, 2 decimals | ✅ | `SoukPrice` widget + `formatAed()` (R3); covered by `souk_price_test`. |
| NFR-17 | 44×44pt min touch targets | 🟡 | Most buttons use standard Material sizing; **a few custom 36–40px circular icon buttons** (e.g. compact icon buttons) should be spot-checked/bumped. |
| NFR-18 | Dynamic Type / font scaling without clipping | 🟡 | Many `GoogleFonts` fixed sizes; **needs a large-text-scale pass** for clipping. |
| NFR-19 | Accessibility labels (VoiceOver/TalkBack) | 🟡 | Some `Semantics`/tooltips present (e.g. search, cart); a full screen-reader sweep is pending (PRD §14 audit). |
| NFR-20 | Full RTL when Arabic | ✅ | `DirectionalIcon`, ARB-driven strings, RTL-aware layouts; B5/B6 removed the freshness label parsing that broke in Arabic. |

## Recommended follow-up tasks (small, additive)
- **UI-02:** confirm/add the "Also at <store> — AED x.xx" secondary line in cart rows.
- **UI-03:** wrap the home token balance in a count-up (`TweenAnimationBuilder`) on increase.
- **NFR-17:** audit custom `IconButton`/`GestureDetector` hit areas < 44pt; wrap in `SizedBox(48,48)` or add `padding`.
- **NFR-18/19:** run a `textScaleFactor: 1.5` + screen-reader pass (ties into PRD §14 accessibility audit).

The high-frequency, trust-critical surfaces (price format, freshness, RTL, live
token estimate) are conformant. Remaining items are polish/accessibility, suitable
for a focused pre-launch UI pass.
