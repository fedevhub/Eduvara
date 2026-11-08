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
    final legacyRole = map['id_role'];
    final roleFromId = switch (int.tryParse(legacyRole?.toString() ?? '')) {
      1 => 'admin',
      2 => 'teacher',
      3 => 'student',
      _ => legacyRole?.toString() ?? '',
    };
    final rawRole = (map['role'] ?? roleFromId).toString().trim().toLowerCase();
    final role = switch (rawRole) {
      'guru' => 'teacher',
      'siswa' => 'student',
      'administrator' => 'admin',
      _ => rawRole,
    };

    return AuthUserModel(
      id: (map['id'] ?? map['id_user']).toString(),
      email: (map['email'] ?? email).toString(),
      name: (map['full_name'] ?? map['nama_lengkap'] ?? email).toString(),
      role: role,
    );
  }
}
