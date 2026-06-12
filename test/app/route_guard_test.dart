import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/app/route_guard.dart';

void main() {
  group('admin route guard', () {
    test('guest cannot access admin', () {
      final redirect = resolveRouteRedirect(
        matchedLocation: '/admin',
        isAuthUnknown: false,
        isUnauthenticated: false,
        isGuest: true,
        isAdmin: false,
      );

      expect(redirect, '/welcome');
    });

    test('normal user cannot access admin', () {
      final redirect = resolveRouteRedirect(
        matchedLocation: '/admin',
        isAuthUnknown: false,
        isUnauthenticated: false,
        isGuest: false,
        isAdmin: false,
      );

      expect(redirect, '/unauthorized');
    });

    test('admin user can access admin', () {
      final redirect = resolveRouteRedirect(
        matchedLocation: '/admin',
        isAuthUnknown: false,
        isUnauthenticated: false,
        isGuest: false,
        isAdmin: true,
      );

      expect(redirect, isNull);
    });
  });
}
