import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<UserModel>> getUsers() async {
    final rows = await _db
        .from('user')
        .select(
          'id_user, id_role, nama_lengkap, username, nisn, status, nip, mapel, kelas, created_at',
        )
        .order('nama_lengkap');
    return rows
        .map<UserModel>((r) => UserModel.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<UserModel> getUser(String id) async {
    final row = await _db
        .from('user')
        .select(
          'id_user, id_role, nama_lengkap, username, nisn, status, nip, mapel, kelas, created_at',
        )
        .eq('id_user', id)
        .single();
    return UserModel.fromMap(Map<String, dynamic>.from(row));
  }

  Map<String, dynamic> _userRow({
    required String name,
    required String username,
    required String role,
    required bool active,
    String? mapel,
    String? kelas,
  }) => {
    'id_role': UserModel.idForRole(role),
    'nama_lengkap': name,
    'status': active ? 'aktif' : 'nonaktif',
    'username': username.trim().toLowerCase(),
    'nisn': role == 'student' ? username.trim() : null,
    'nip': role == 'teacher' ? username.trim() : null,
    'mapel': role == 'teacher' ? mapel : null,
    'kelas': role == 'student' ? kelas : null,
  };

  Future<void> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
    required bool active,
    String? mapel,
    String? kelas,
  }) async {
    try {
      await _db.functions.invoke(
        'admin-create-user',
        body: {
          'name': name.trim(),
          'username': username.trim(),
          'password': password,
          'role': role,
          'active': active,
          'mapel': mapel,
          'kelas': kelas,
        },
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['code']?.toString() : null;
      throw AuthException(switch (code) {
        'username_taken' => 'Username sudah digunakan. Gunakan username lain.',
        'migration_required' =>
          'Database username belum disiapkan. Terapkan migrasi Supabase terbaru.',
        'NOT_FOUND' || 'not_found' =>
          'Fungsi pembuatan pengguna belum di-deploy ke Supabase.',
        _ => details is Map
            ? details['message']?.toString() ?? 'Pembuatan pengguna gagal.'
            : 'Pembuatan pengguna gagal.',
      });
    }
  }

  Future<void> updateUser({
    required UserModel old,
    required String name,
    required String username,
    required String role,
    required bool active,
    String? mapel,
    String? kelas,
  }) async {
    await _db
        .from('user')
        .update({
          ..._userRow(
            name: name,
            username: username,
            role: role,
            active: active,
            mapel: mapel,
            kelas: kelas,
          ),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id_user', old.id);

    await _db.from('profiles').upsert({
      'id': old.id,
      'full_name': name,
      'role': role,
    });
  }

  Future<void> setStatus(String id, bool active) async {
    await _db
        .from('user')
        .update({
          'status': active ? 'aktif' : 'nonaktif',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id_user', id);
  }

  Future<void> deleteUser(String id) async {
    await _db.rpc('admin_delete_user', params: {'target': id});
  }
}
