class UserModel {
  final String id;
  final int idRole;
  final String name;
  final String? username;
  final String? nisn;
  final String status;
  final String? nip;
  final String? mapel;
  final String? kelas;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.idRole,
    required this.name,
    this.username,
    this.nisn,
    this.status = 'aktif',
    this.nip,
    this.mapel,
    this.kelas,
    this.createdAt,
  });

  // Sesuaikan angka ini dengan isi tabel role kamu.
  static const Map<String, int> roleIds = {
    'admin': 1,
    'teacher': 2,
    'student': 3,
  };

  static int idForRole(String role) => roleIds[role] ?? 3;

  static String roleForId(int id) => roleIds.entries
      .firstWhere(
        (e) => e.value == id,
        orElse: () => const MapEntry('student', 3),
      )
      .key;

  String get role => roleForId(idRole);

  String get loginUsername => switch (role) {
    'student' => nisn?.isNotEmpty == true ? nisn! : username ?? '',
    'teacher' => nip?.isNotEmpty == true ? nip! : username ?? '',
    _ => username ?? '',
  };

  String get roleLabel => switch (role) {
    'admin' => 'Admin',
    'teacher' => 'Guru',
    _ => 'Siswa',
  };

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'aktif' || s == 'active' || s == 'true';
  }

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id_user'].toString(),
    idRole: (m['id_role'] as num?)?.toInt() ?? 3,
    name: (m['nama_lengkap'] ?? '').toString(),
    username: m['username']?.toString(),
    nisn: m['nisn']?.toString(),
    status: (m['status'] ?? 'aktif').toString(),
    nip: m['nip']?.toString(),
    mapel: m['mapel']?.toString(),
    kelas: m['kelas']?.toString(),
    createdAt: DateTime.tryParse((m['created_at'] ?? '').toString())?.toLocal(),
  );
}
