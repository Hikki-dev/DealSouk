enum ModerationStatus { pending, approved, rejected, hidden }

class FlagState {
  final Set<String> uniqueFlaggerIds;
  final ModerationStatus status;

  const FlagState({
    this.uniqueFlaggerIds = const {},
    this.status = ModerationStatus.pending,
  });

  int get count => uniqueFlaggerIds.length;
  bool get hidden => status == ModerationStatus.hidden;
}

FlagState addUniqueFlag(FlagState state, String flaggerId) {
  final flaggers = {...state.uniqueFlaggerIds, flaggerId};
  return FlagState(
    uniqueFlaggerIds: flaggers,
    status: flaggers.length >= 3 ? ModerationStatus.hidden : state.status,
  );
}

ModerationStatus approveSubmission(ModerationStatus current) {
  if (current == ModerationStatus.hidden) return current;
  return ModerationStatus.approved;
}

ModerationStatus rejectSubmission(ModerationStatus current) {
  if (current == ModerationStatus.hidden) return current;
  return ModerationStatus.rejected;
}
