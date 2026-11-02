import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<UserModel>> getUsers() async {
    final rows = await _db
        .from('user')
        .select(
          'id_user, id_role, nama_lengkap, email, status, nip, mapel, kelas, created_at',
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
          'id_user, id_role, nama_lengkap, email, status, nip, mapel, kelas, created_at',
        )
        .eq('id_user', id)
        .single();
    return UserModel.fromMap(Map<String, dynamic>.from(row));
  }

  Map<String, dynamic> _userRow({
    required String name,
    required String email,
    required String role,
    required bool active,
    String? nip,
    String? mapel,
    String? kelas,
  }) => {
    'id_role': UserModel.idForRole(role),
    'nama_lengkap': name,
    'email': email,
    'status': active ? 'aktif' : 'nonaktif',
    'nip': role == 'teacher' ? nip : null,
    'mapel': role == 'teacher' ? mapel : null,
    'kelas': role == 'student' ? kelas : null,
  };

  /// Buat akun Auth lewat client terpisah, lalu simpan profil dan data user
  /// dalam satu transaksi database tanpa mengubah sesi admin.
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool active,
    String? nip,
    String? mapel,
    String? kelas,
  }) async {
    final adminSession = _db.auth.currentSession;
    if (adminSession == null) {
      throw const AuthException(
        'Sesi admin tidak ditemukan. Silakan login ulang.',
      );
    }
    final adminRefreshToken = adminSession.refreshToken;
    if (adminRefreshToken == null) {
      throw const AuthException(
        'Sesi admin sudah tidak valid. Silakan login ulang.',
      );
    }

    final temp = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.publishableKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );
    final adminDb = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.publishableKey,
      accessToken: () async => adminSession.accessToken,
    );
    String? newId;

    try {
      final adminProfile = await adminDb
          .from('profiles')
          .select('role')
          .eq('id', adminSession.user.id)
          .maybeSingle();
      if (adminProfile?['role'] != 'admin') {
        throw const AuthException(
          'Sesi admin tidak valid. Silakan logout lalu login kembali.',
        );
      }

      final res = await temp.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': role},
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Akun tidak berhasil dibuat.');
      }
      if (user.identities != null && user.identities!.isEmpty) {
        throw const AuthException('Email sudah digunakan.');
      }
      newId = user.id;

      await adminDb.rpc(
        'admin_create_user',
        params: {
          'p_target': newId,
          'p_full_name': name,
          'p_role': role,
          'p_active': active,
          'p_nip': nip,
          'p_mapel': mapel,
          'p_kelas': kelas,
        },
      );
    } catch (e) {
      // Kalau gagal di tengah jalan, batalkan akun auth yang sudah terbuat.
      if (newId != null) {
        try {
          await adminDb.rpc('admin_delete_user', params: {'target': newId});
        } catch (cleanupError) {
          throw StateError(
            'Pembuatan profil gagal ($e), dan akun Auth sementara '
            'tidak dapat dibersihkan ($cleanupError).',
          );
        }
      }
      rethrow;
    } finally {
      // The signup client may update shared browser auth storage.
      if (_db.auth.currentUser?.id != adminSession.user.id) {
        try {
          await _db.auth.setSession(adminRefreshToken);
        } catch (_) {}
      }
      adminDb.dispose();
      temp.dispose();
    }
  }

  Future<void> updateUser({
    required UserModel old,
    required String name,
    required String email,
    required String role,
    required bool active,
    String? nip,
    String? mapel,
    String? kelas,
  }) async {
    final emailChanged = email != old.email;

    if (emailChanged) {
      await _db.rpc(
        'admin_update_auth_user',
        params: {'target': old.id, 'new_email': email, 'new_password': null},
      );
    }

    await _db
        .from('user')
        .update({
          ..._userRow(
            name: name,
            email: email,
            role: role,
            active: active,
            nip: nip,
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
