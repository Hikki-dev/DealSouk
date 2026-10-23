# DealSouk design system

One system for phone, tablet and desktop, in English and Arabic (RTL). Code lives in `lib/core/design/`; import `package:dealsouk/core/design/design.dart`.

## Principles
- **Everyone, 14 to 65.** 16px minimum body text, 48px minimum touch targets, 52px buttons, text never colour-only (tags carry words and icons).
- **Flat and fast.** Solid cards with a hairline border. No blur or glass effects, so scrolling stays smooth on mid-range phones.
- **Dubai first.** Bundled Dubai photography, real store logos, AED prices (`د.إ` and Arabic-Indic digits in Arabic), Mapbox map tiles.
- **Comfort text.** Layouts are tested at 160% text scale. Buttons and labels wrap rather than truncate.

## Tokens (`lib/core/theme/theme.dart`)
| Token | Value | Use |
|---|---|---|
| Teal (`forestDeep`) | `#084F52` | Primary actions, selected states |
| Teal (`emerald`) | `#0B6B6B` | Brand, links |
| Saffron (`limeAccent`) | `#F2A91B` | Rewards, "share a price" |
| Sand (`background`) | `#FBF6EC` | Page background |
| Ink | `#1B2730` | Text |
| Good / Warn / Bad | green / amber / red with light + text variants | Status tags and banners |

Fonts: bundled **Readex Pro** 400/500/600/700 (Latin and Arabic) via `AppFonts.display` / `AppFonts.body`. No font is fetched at runtime.

## Breakpoints (`breakpoints.dart`)
| Class | Width | Navigation |
|---|---|---|
| compact | < 600 | Bottom bar (Home, Map, My list, Rewards, Profile) |
| medium | 600 to 1023 | 96px side rail |
| expanded | ≥ 1024 | Top bar with links, search and language switch |

`PageContainer` centres content at a 1200px maximum. `AdaptiveGrid` picks 2, 3 or 4 columns. Use `context.screenClass` / `context.isExpanded` for layout switches.

## Components (`components/`)
- **Buttons:** `DsButton` (primary, secondary, accent, ghost, danger, google, apple), `DsIconButton`.
- **Labels:** `DsTag`, `DsChip`, `DsChipRow`, `DsPrice`.
- **Surfaces:** `DsCard`, `DsBanner`, `DsSkeleton`, `DsListRowSkeleton`, `DsSegmented`, `DsProgressBar`, `DsStepBar`, `DsSectionHeader`.
- **Media:** `DsPhotos`, `DsPhotoBanner`, `DsProductThumb` (network or `asset:`), `DsStoreLogo`, `DsAvatar`, `DsEmptyState`.
- **Navigation:** `DsBottomNav`, `DsRail`, `DsTopNav`, `DsAppBar`, `DsBrandMark`.

## Performance
- Photos are bundled JPEGs, decoded at display size (`cacheWidth`).
- Product images use `CachedNetworkImage` with `memCacheWidth: 360`.
- Skeleton loaders replace spinners; they stop when the OS asks to reduce motion.
- Fonts are bundled, so first paint does not wait on a font download.

## Accessibility
- Semantics labels on buttons, prices (`AED 9.50`), images and checkboxes.
- Visible focus ring on buttons; keyboard navigation on desktop.
- Contrast: text on photos sits on a dark teal fade for 4.5:1.

## Testing
`test/screenshots/` renders screens with fake data at phone (390x844), tablet (820x1180) and desktop (1440x900), in English, Arabic, and 160% text. PNGs are written to `build/screenshots/`. Any overflow fails the test, so these double as layout smoke tests.

## Photo credits
Listed in the app under Profile, Privacy & Terms, and in the README "design assets & credits" section.
