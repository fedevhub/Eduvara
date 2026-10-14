import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository = AuthRepository();
  UserModel? user;
  bool loading = false;

  Future<void> login(String username, String password, String role) async {
    loading = true;
    notifyListeners();
    user = await repository.login(username, password, role);
    loading = false;
    notifyListeners();
  }

  void logout() {
    user = null;
    notifyListeners();
  }
}
