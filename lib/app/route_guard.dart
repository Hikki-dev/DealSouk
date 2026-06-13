String? resolveRouteRedirect({
  required String matchedLocation,
  required bool isAuthUnknown,
  required bool isUnauthenticated,
  required bool isGuest,
  required bool isAdmin,
  // Debug-only: lets a guest open /profile so the screen can be QA'd in the
  // browser without signing in. Production builds pass false (FR-03 enforced).
  bool allowGuestProfile = false,
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

  if (isGuest && matchedLocation.startsWith('/submit-price')) {
    return '/';
  }

  if (isGuest && matchedLocation == '/profile' && !allowGuestProfile) {
    return '/';
  }

  return null;
}
