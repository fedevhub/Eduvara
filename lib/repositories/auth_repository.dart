import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user_model.dart';
import 'profile_repository.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  final ProfileRepository _profileRepository = ProfileRepository();

  Future<void> _ensureActive(String userId) async {
    final row = await _supabase
        .from('user')
        .select('status')
        .eq('id_user', userId)
        .maybeSingle();

    final status = (row?['status'] ?? 'aktif').toString().toLowerCase();

    if (status == 'nonaktif' || status == 'inactive' || status == 'false') {
      throw Exception('Akun kamu dinonaktifkan. Hubungi admin.');
    }
  }

  Future<AuthUserModel> login(String username, String password) async {
    final FunctionResponse response;
    try {
      response = await _supabase.functions.invoke(
        'username-auth',
        body: {'username': username.trim(), 'password': password},
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['code']?.toString() : null;
      throw AuthException(switch (code) {
        'reset_pending' => 'reset_pending',
        'invalid_credentials' => 'invalid_credentials',
        'account_inactive' => 'account_inactive',
        'NOT_FOUND' || 'not_found' => 'username_auth_not_deployed',
        _ => 'Login tidak dapat diproses.',
      });
    }

    final result = response.data;
    if (response.status != 200 || result is! Map || result['code'] != null) {
      final code = result is Map ? result['code']?.toString() : null;
      throw AuthException(switch (code) {
        'reset_pending' => 'reset_pending',
        'invalid_credentials' => 'invalid_credentials',
        'account_inactive' => 'account_inactive',
        'migration_required' => 'username_migration_required',
        _ => 'Login tidak dapat diproses.',
      });
    }

    final refreshToken = result['refresh_token']?.toString();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('Login tidak dapat diproses.');
    }
    final session = await _supabase.auth.setSession(refreshToken);
    final authUser = session.user;

    if (authUser == null) {
      throw Exception('Login gagal. Silakan coba lagi.');
    }

    try {
      final profile = await _profileRepository.getProfile(
        userId: authUser.id,
        email: authUser.email ?? '',
        username: username,
      );

      const validRoles = ['admin', 'teacher', 'student'];

      if (!validRoles.contains(profile.role)) {
        throw Exception('Role akun tidak valid.');
      }

      await _ensureActive(authUser.id);

      return profile;
    } catch (_) {
      await _supabase.auth.signOut();
      rethrow;
    }
  }

  Future<AuthUserModel?> restoreSession() async {
    final authUser = _supabase.auth.currentUser;

    if (authUser == null) {
      return null;
    }

    try {
      await _ensureActive(authUser.id);

      return await _profileRepository.getProfile(
        userId: authUser.id,
        email: authUser.email ?? '',
        username: authUser.userMetadata?['username']?.toString() ?? '',
      );
    } catch (_) {
      await _supabase.auth.signOut();
      return null;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
