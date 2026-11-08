import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthUserModel> getProfile({
    required String userId,
    required String email,
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

    if (data != null) return AuthUserModel.fromMap(data, email);

    final legacyUser = await _supabase
        .from('user')
        .select('id_user, id_role, nama_lengkap')
        .eq('id_user', userId)
        .maybeSingle();
    if (legacyUser == null) {
      throw const AuthException(
        'Profil akun tidak ditemukan pada tabel profiles maupun user.',
      );
    }

    return AuthUserModel.fromMap(legacyUser, email);
  }
}
