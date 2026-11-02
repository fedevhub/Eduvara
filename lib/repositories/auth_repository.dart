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

  Future<AuthUserModel> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final authUser = response.user;

    if (authUser == null) {
      throw Exception('Login gagal. Silakan coba lagi.');
    }

    try {
      final profile = await _profileRepository.getProfile(
        userId: authUser.id,
        email: authUser.email ?? email,
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
