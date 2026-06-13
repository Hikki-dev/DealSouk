class UserBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool unlocked;

  const UserBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.unlocked,
  });

  UserBadge copyWith({bool? unlocked}) {
    return UserBadge(
      id: id,
      name: name,
      emoji: emoji,
      description: description,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}
