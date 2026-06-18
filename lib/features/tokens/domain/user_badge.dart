class UserBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool unlocked;
  final String? unlockedAtLabel;

  const UserBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.unlocked,
    this.unlockedAtLabel,
  });

  UserBadge copyWith({bool? unlocked, String? unlockedAtLabel}) {
    return UserBadge(
      id: id,
      name: name,
      emoji: emoji,
      description: description,
      unlocked: unlocked ?? this.unlocked,
      unlockedAtLabel: unlockedAtLabel ?? this.unlockedAtLabel,
    );
  }
}
