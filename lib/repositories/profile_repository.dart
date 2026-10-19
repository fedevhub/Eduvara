import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthUserModel> getProfile({
    required String userId,
    required String email,
  }) async {
    final data = await _supabase
        .from('profiles')
        .select('id, full_name, role')
        .eq('id', userId)
        .single();

    return AuthUserModel.fromMap(data, email);
  }
}
