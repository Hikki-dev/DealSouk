String? resolveRouteRedirect({
  required String matchedLocation,
  required bool isAuthUnknown,
  required bool isUnauthenticated,
  required bool isGuest,
  required bool isAdmin,
}) {
  final onWelcome = matchedLocation == '/welcome';
  final onUnauthorized = matchedLocation == '/unauthorized';
  final onAdmin = matchedLocation == '/admin';

  if (isAuthUnknown) return null;

  if (isUnauthenticated) {
    return onWelcome ? null : '/welcome';
  }

  if (onWelcome) return '/';

  if (onAdmin && !isAdmin) {
    return isGuest ? '/welcome' : '/unauthorized';
  }

  if (isAdmin && onUnauthorized) return '/admin';

  if (isGuest &&
      (matchedLocation.startsWith('/submit-price') ||
          matchedLocation == '/profile')) {
    return '/';
  }

  return null;
}
