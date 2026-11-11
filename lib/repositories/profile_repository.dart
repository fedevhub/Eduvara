import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthUserModel> getProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    Map<String, dynamic>? data;
    try {
      data = await _supabase
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', userId)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (!{'PGRST205', 'PGRST204', '42P01', '42703'}.contains(error.code)) {
        rethrow;
      }
    }

    final account = await _supabase
        .from('user')
        .select('id_user, id_role, nama_lengkap, username, nisn, nip')
        .eq('id_user', userId)
        .maybeSingle();
    if (account == null) {
      throw const AuthException(
        'Profil akun tidak ditemukan pada tabel profiles maupun user.',
      );
    }

    final roleUsername = switch ((account['id_role'] as num?)?.toInt()) {
      3 => account['nisn'],
      2 => account['nip'],
      _ => account['username'],
    };
    final accountUsername =
        (roleUsername ?? account['username'] ?? username).toString();
    return AuthUserModel.fromMap({
      ...?data,
      ...account,
      'username': accountUsername,
    }, email, username: accountUsername);
  }
}
