enum AuthRole {
  user,
  admin,

  /// Signed in, may look around the moderator console but not change anything.
  demo;

  static AuthRole? fromClaim(Object? claim) {
    final value = claim?.toString().trim().toLowerCase();
    return switch (value) {
      'admin' => AuthRole.admin,
      'user' => AuthRole.user,
      _ => null,
    };
  }

  static Set<AuthRole> fromClaims(Map<String, dynamic> claims) {
    final roles = <AuthRole>{};

    final rolesClaim = claims['roles'];
    if (rolesClaim is Iterable) {
      for (final role in rolesClaim) {
        final parsed = AuthRole.fromClaim(role);
        if (parsed != null) roles.add(parsed);
      }
    }

    final roleClaim = AuthRole.fromClaim(claims['role']);
    if (roleClaim != null) roles.add(roleClaim);

    // Backward-compatible bridge while the backend still exposes isAdmin.
    if (claims['isAdmin'] == true) roles.add(AuthRole.admin);

    if (claims['demoViewer'] == true) roles.add(AuthRole.demo);

    if (roles.isEmpty) roles.add(AuthRole.user);
    return roles;
  }
}
