import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository repository = UserRepository();
  List<UserModel> items = [];
  Future<void> load() async {
    items = await repository.getUsers();
    notifyListeners();
  }
}
