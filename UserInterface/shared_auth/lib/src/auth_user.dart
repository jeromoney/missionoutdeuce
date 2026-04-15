class AuthTeamMembership {
  const AuthTeamMembership({
    required this.teamPublicId,
    required this.teamName,
    required this.roles,
  });

  final String teamPublicId;
  final String teamName;
  final List<String> roles;

  Map<String, dynamic> toJson() {
    return {
      'team_public_id': teamPublicId,
      'team_name': teamName,
      'roles': roles,
    };
  }

  factory AuthTeamMembership.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

    return AuthTeamMembership(
      teamPublicId: json['team_public_id'] as String? ?? '',
      teamName: json['team_name'] as String? ?? 'Unknown Team',
      roles: roles,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.publicId,
    required this.name,
    required this.initials,
    required this.role,
    required this.email,
    this.globalPermissions = const [],
    this.teamMemberships = const [],
  });

  final String publicId;
  final String name;
  final String initials;
  final String role;
  final String email;
  final List<String> globalPermissions;
  final List<AuthTeamMembership> teamMemberships;

  factory AuthUser.fromJson(
    Map<String, dynamic> json, {
    String? requestedClient,
    String? fallbackRole,
  }) {
    final globalPermissions =
        (json['global_permissions'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList();
    final teamMemberships =
        (json['team_memberships'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AuthTeamMembership.fromJson)
            .toList();

    return AuthUser(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown User',
      initials: json['initials'] as String? ?? '--',
      role:
          json['role'] as String? ??
          _resolveRoleLabel(
            requestedClient: requestedClient,
            fallbackRole: fallbackRole,
            globalPermissions: globalPermissions,
            teamMemberships: teamMemberships,
          ),
      email: json['email'] as String? ?? '',
      globalPermissions: globalPermissions,
      teamMemberships: teamMemberships,
    );
  }

  AuthUser copyWith({
    String? publicId,
    String? name,
    String? initials,
    String? role,
    String? email,
    List<String>? globalPermissions,
    List<AuthTeamMembership>? teamMemberships,
  }) {
    return AuthUser(
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      role: role ?? this.role,
      email: email ?? this.email,
      globalPermissions: globalPermissions ?? this.globalPermissions,
      teamMemberships: teamMemberships ?? this.teamMemberships,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'name': name,
      'initials': initials,
      'email': email,
      'global_permissions': globalPermissions,
      'team_memberships': teamMemberships
          .map((membership) => membership.toJson())
          .toList(),
    };
  }
}

String _resolveRoleLabel({
  String? requestedClient,
  String? fallbackRole,
  required List<String> globalPermissions,
  required List<AuthTeamMembership> teamMemberships,
}) {
  switch (requestedClient) {
    case 'team_admin':
      return 'Team Admin';
    case 'dispatcher':
      return 'Dispatcher';
    case 'responder':
      return 'Responder';
  }

  if (globalPermissions.contains('super_admin')) {
    return 'Super Admin';
  }

  final allRoles = teamMemberships.expand((membership) => membership.roles);
  if (allRoles.contains('team_admin')) {
    return 'Team Admin';
  }
  if (allRoles.contains('dispatcher')) {
    return 'Dispatcher';
  }
  if (allRoles.contains('responder')) {
    return 'Responder';
  }

  return fallbackRole ?? 'Responder';
}
