/// Shared display formatters (R3) so price/currency strings can't drift.
///
/// Formats an AED price as a String, e.g. 14.7 -> "AED 14.70" (UI-05: always
/// two decimals). Use this wherever a plain price String is needed; for a
/// styled price use the `SoukPrice` widget instead.
String formatAed(num value) => 'AED ${value.toStringAsFixed(2)}';
