import '../models/user_model.dart';

class UserRepository {
  Future<List<UserModel>> getUsers() async => const [
    UserModel(id: 1, name: 'Admin Eduvara', username: 'admin', role: 'admin'),
    UserModel(
      id: 2,
      name: 'Teacher Eduvara',
      username: 'teacher',
      role: 'teacher',
    ),
    UserModel(
      id: 3,
      name: 'Student Eduvara',
      username: 'student',
      role: 'student',
    ),
  ];
}
