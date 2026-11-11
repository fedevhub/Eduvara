import 'package:eduvara/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses student NISN as the displayed username', () {
    final user = UserModel.fromMap({
      'id_user': 'student-id',
      'id_role': 3,
      'nama_lengkap': 'Siswa',
      'nisn': '0012345678',
      'username': '0012345678',
    });

    expect(user.loginUsername, '0012345678');
  });

  test('uses teacher NIP as the displayed username', () {
    final user = UserModel.fromMap({
      'id_user': 'teacher-id',
      'id_role': 2,
      'nama_lengkap': 'Guru',
      'nip': '198901012020011001',
      'username': '198901012020011001',
    });

    expect(user.loginUsername, '198901012020011001');
  });

  test('uses the administrator-selected username', () {
    final user = UserModel.fromMap({
      'id_user': 'admin-id',
      'id_role': 1,
      'nama_lengkap': 'Admin',
      'username': 'admin-satu',
    });

    expect(user.loginUsername, 'admin-satu');
  });
}
