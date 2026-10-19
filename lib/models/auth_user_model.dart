class AuthUserModel {
  final String id;
  final String email;
  final String name;
  final String role;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AuthUserModel.fromMap(Map<String, dynamic> map, String email) {
    return AuthUserModel(
      id: map['id'].toString(),
      email: email,
      name: map['full_name'] as String,
      role: map['role'] as String,
    );
  }
}
