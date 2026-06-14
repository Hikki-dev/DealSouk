/// Time-of-day buckets for the home-screen greeting ("Good morning, Max").
enum DayPart { morning, afternoon, evening }

/// Pure mapping from a 24-hour clock hour to a [DayPart]:
///   00:00–11:59 → morning · 12:00–16:59 → afternoon · 17:00–23:59 → evening
DayPart dayPartForHour(int hour) {
  if (hour < 12) return DayPart.morning;
  if (hour < 17) return DayPart.afternoon;
  return DayPart.evening;
}
