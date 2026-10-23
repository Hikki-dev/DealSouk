import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'harness.dart';

void main() {
  const body = Center(child: Text('Tab content'));

  testWidgets('shell on phone', (tester) async {
    await shoot(
      tester,
      const ShellFrame(locationOverride: '/', child: body),
      name: 'shell_phone',
    );
  });

  testWidgets('shell on tablet', (tester) async {
    await shoot(
      tester,
      const ShellFrame(locationOverride: '/stores', child: body),
      name: 'shell_tablet',
      size: Sizes.tablet,
    );
  });

  testWidgets('shell on desktop', (tester) async {
    await shoot(
      tester,
      const ShellFrame(locationOverride: '/leaderboard', child: body),
      name: 'shell_desktop',
      size: Sizes.desktop,
    );
  });
}
