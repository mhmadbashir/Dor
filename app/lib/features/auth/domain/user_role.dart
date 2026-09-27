enum UserRole {
  household,
  driver,
  admin;

  static UserRole fromName(String name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.household);
}
