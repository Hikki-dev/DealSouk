const priceFreshnessWindow = Duration(hours: 72);

bool isFreshPrice(DateTime submittedAt, DateTime now) {
  return !submittedAt.isAfter(now) &&
      now.difference(submittedAt) < priceFreshnessWindow;
}

List<T> freshOnly<T>({
  required Iterable<T> prices,
  required DateTime now,
  required DateTime Function(T price) submittedAt,
}) {
  return prices
      .where((price) => isFreshPrice(submittedAt(price), now))
      .toList();
}
