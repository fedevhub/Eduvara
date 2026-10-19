import 'package:flutter/foundation.dart';

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
    } catch (e) {
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
    final message = error.toString();

    if (message.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }

    if (message.contains('PGRST116') ||
        message.contains('JSON object requested')) {
      return 'Profil akun tidak ditemukan.';
    }

    if (message.contains('Failed host lookup') ||
        message.contains('SocketException')) {
      return 'Tidak dapat terhubung ke internet.';
    }

    if (message.contains('Email not confirmed')) {
      return 'Silakan verifikasi email akun kamu.';
    }

    return 'Login gagal. Periksa akun dan koneksi internet.';
  }
}
