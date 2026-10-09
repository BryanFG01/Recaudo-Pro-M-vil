/// Pantallas que se pueden ver sin sesión.
const Set<String> publicRoutes = {'/game-intro', '/business-selection', '/login'};

/// Regla de navegación según la sesión (función pura, testeable).
/// - Mientras se restaura la sesión guardada no se redirige.
/// - Sin sesión, una pantalla protegida lleva al login.
/// - Con sesión, el login lleva al dashboard.
String? authRedirect({
  required String location,
  required bool isRestored,
  required bool isLoggedIn,
}) {
  if (!isRestored) return null;
  final isPublic = publicRoutes.contains(location);
  if (!isLoggedIn && !isPublic) return '/login';
  if (isLoggedIn && location == '/login') return '/dashboard';
  return null;
}
