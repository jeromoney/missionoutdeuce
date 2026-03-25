class AuthUser {
  const AuthUser({
    required this.name,
    required this.initials,
    required this.role,
    required this.email,
  });

  final String name;
  final String initials;
  final String role;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      name: json['name'] as String? ?? 'Unknown User',
      initials: json['initials'] as String? ?? '--',
      role: json['role'] as String? ?? 'Responder',
      email: json['email'] as String? ?? '',
    );
  }

  AuthUser copyWith({
    String? name,
    String? initials,
    String? role,
    String? email,
  }) {
    return AuthUser(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      role: role ?? this.role,
      email: email ?? this.email,
    );
  }
}
