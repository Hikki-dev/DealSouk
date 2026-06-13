class DailyChallenge {
  final String id;
  final String description;
  final String targetStore;
  final int targetCount;
  final int bonusTokens;
  final int progressCount;
  final bool completed;

  const DailyChallenge({
    required this.id,
    required this.description,
    required this.targetStore,
    required this.targetCount,
    required this.bonusTokens,
    this.progressCount = 0,
    this.completed = false,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    final progress = json['userProgress'] as Map<String, dynamic>?;
    return DailyChallenge(
      id: json['id'] as String,
      description:
          json['description'] as String? ??
          json['title'] as String? ??
          'Submit fresh prices today',
      targetStore: json['chainTarget'] as String? ?? 'Any',
      targetCount: json['targetCount'] as int? ?? 3,
      bonusTokens: json['bonusTokens'] as int? ?? 30,
      progressCount: progress?['progress'] as int? ?? 0,
      completed: progress?['completed'] as bool? ?? false,
    );
  }

  DailyChallenge copyWith({int? progressCount, bool? completed}) {
    return DailyChallenge(
      id: id,
      description: description,
      targetStore: targetStore,
      targetCount: targetCount,
      bonusTokens: bonusTokens,
      progressCount: progressCount ?? this.progressCount,
      completed: completed ?? this.completed,
    );
  }
}
