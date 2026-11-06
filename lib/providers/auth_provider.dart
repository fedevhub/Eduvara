import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository = AuthRepository();

  AuthUserModel? user;
  bool loading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      user = await repository.login(email, password);
      return true;
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] Login gagal: $e');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = _getErrorMessage(e);
      user = null;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    loading = true;
    notifyListeners();

    try {
      user = await repository.restoreSession();
    } catch (_) {
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repository.logout();

    user = null;
    errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(Object error) {
    final message = switch (error) {
      AuthException(:final message) => message,
      PostgrestException(:final message) => message,
      _ => error.toString(),
    };
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials')) {
      return 'Email atau password salah.';
    }

    if ((error is PostgrestException && error.code == 'PGRST116') ||
        normalized.contains('json object requested') ||
        normalized.contains('0 rows')) {
      return 'Profil akun tidak ditemukan.';
    }

    if (normalized.contains('failed host lookup') ||
        normalized.contains('socketexception') ||
        normalized.contains('clientexception') ||
        normalized.contains('handshakeexception') ||
        normalized.contains('xmlhttprequest error')) {
      return 'Tidak dapat terhubung ke internet.';
    }

    if (normalized.contains('email not confirmed') ||
        normalized.contains('email_not_confirmed')) {
      return 'Silakan verifikasi email akun kamu.';
    }

    if (normalized.contains('dinonaktifkan')) {
      return 'Akun kamu dinonaktifkan. Hubungi admin.';
    }

    if (normalized.contains('role akun tidak valid')) {
      return 'Role akun tidak valid. Hubungi admin untuk memperbaiki profil.';
    }

    if (error is PostgrestException) {
      if (error.code == '42501' ||
          normalized.contains('permission denied') ||
          normalized.contains('row-level security')) {
        return 'Login berhasil, tetapi Supabase menolak pembacaan profil (RLS). Pastikan akun dapat membaca barisnya sendiri di tabel profiles atau user.';
      }
      if (error.code == 'PGRST205' ||
          normalized.contains('could not find the table')) {
        return 'Login berhasil, tetapi tabel profiles dan user belum tersedia atau belum masuk ke schema cache Supabase.';
      }
      return 'Login berhasil, tetapi pembacaan profil dari Supabase gagal (${error.code}): ${error.message}';
    }

    return 'Login gagal. Periksa akun dan koneksi internet.';
  }
}
