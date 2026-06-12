class StreakData {
  final int currentStreak;
  final int longestStreak;
  final String lastActivityLabel;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityLabel,
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastActivityLabel,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityLabel: lastActivityLabel ?? this.lastActivityLabel,
    );
  }
}
