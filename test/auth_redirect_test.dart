import 'package:flutter_test/flutter_test.dart';
import 'package:RecaudoPro/presentation/routes/auth_redirect.dart';

void main() {
  group('authRedirect', () {
    test('mientras se restaura la sesión no redirige', () {
      expect(authRedirect(location: '/dashboard', isRestored: false, isLoggedIn: false), isNull);
    });

    test('sin sesión, una pantalla protegida lleva al login', () {
      expect(authRedirect(location: '/dashboard', isRestored: true, isLoggedIn: false), '/login');
      expect(authRedirect(location: '/cash-session/abc', isRestored: true, isLoggedIn: false), '/login');
    });

    test('sin sesión, las pantallas públicas se pueden ver', () {
      for (final route in publicRoutes) {
        expect(authRedirect(location: route, isRestored: true, isLoggedIn: false), isNull, reason: route);
      }
    });

    test('con sesión, el login lleva al dashboard', () {
      expect(authRedirect(location: '/login', isRestored: true, isLoggedIn: true), '/dashboard');
    });

    test('con sesión, las pantallas protegidas se ven sin redirigir', () {
      expect(authRedirect(location: '/clients', isRestored: true, isLoggedIn: true), isNull);
    });
  });
}
