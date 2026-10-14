import '../models/user_model.dart';

class AuthRepository {
  Future<UserModel> login(String username, String password, String role) async {
    return UserModel(
      id: 1,
      name: 'Admin Eduvara',
      username: username,
      role: 'admin',
    );
  }
}
