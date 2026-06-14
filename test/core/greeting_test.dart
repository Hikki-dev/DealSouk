import 'package:dealsouk/core/util/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayPartForHour (home greeting)', () {
    test('00:00–11:59 is morning', () {
      for (final h in [0, 5, 8, 11]) {
        expect(dayPartForHour(h), DayPart.morning, reason: 'hour $h');
      }
    });

    test('12:00–16:59 is afternoon', () {
      for (final h in [12, 13, 16]) {
        expect(dayPartForHour(h), DayPart.afternoon, reason: 'hour $h');
      }
    });

    test('17:00–23:59 is evening', () {
      for (final h in [17, 20, 23]) {
        expect(dayPartForHour(h), DayPart.evening, reason: 'hour $h');
      }
    });

    test('boundaries flip exactly at 12 and 17', () {
      expect(dayPartForHour(11), DayPart.morning);
      expect(dayPartForHour(12), DayPart.afternoon);
      expect(dayPartForHour(16), DayPart.afternoon);
      expect(dayPartForHour(17), DayPart.evening);
    });
  });
}
