import 'storage_service.dart';

class AuthService {
  final StorageService storage;
  AuthService(this.storage);

  Future<void> saveSession(String token, String role) async {
    await storage.write('token', token);
    await storage.write('role', role);
  }

  Future<String?> token() => storage.read('token');
  Future<String?> role() => storage.read('role');

  Future<void> logout() async => storage.clear();
}
