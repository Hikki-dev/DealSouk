import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/submissions/domain/submission_moderation.dart';

void main() {
  test('flag count auto-hides after 3 unique flags', () {
    // Protects PRD trust rule: three unique reports hide a suspicious price
    // from normal shoppers until admin review.
    var state = const FlagState();

    state = addUniqueFlag(state, 'user-a');
    state = addUniqueFlag(state, 'user-a');
    state = addUniqueFlag(state, 'user-b');
    expect(state.count, 2);
    expect(state.hidden, isFalse);

    state = addUniqueFlag(state, 'user-c');
    expect(state.count, 3);
    expect(state.hidden, isTrue);
  });

  test('admin approve/reject submission transitions pending status', () {
    // Protects PRD admin moderation rule: admins can approve valid submissions
    // or reject invalid ones before token credit becomes final.
    expect(
      approveSubmission(ModerationStatus.pending),
      ModerationStatus.approved,
    );
    expect(
      rejectSubmission(ModerationStatus.pending),
      ModerationStatus.rejected,
    );
  });
}
