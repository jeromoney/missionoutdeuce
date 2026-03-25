enum AuthRole {
  dispatcher('Dispatcher'),
  responder('Responder'),
  teamAdmin('Team Admin'),
  superAdmin('Super Admin');

  const AuthRole(this.label);

  final String label;
}
