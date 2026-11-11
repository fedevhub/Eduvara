import 'package:eduvara/models/auth_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps legacy user fields and numeric roles', () {
    final model = AuthUserModel.fromMap({
      'id_user': 'user-id',
      'id_role': 2,
      'nama_lengkap': 'Guru Eduvara',
    }, 'guru@example.com');

    expect(model.id, 'user-id');
    expect(model.email, 'guru@example.com');
    expect(model.name, 'Guru Eduvara');
    expect(model.role, 'teacher');
  });

  test('normalizes localized profile roles', () {
    final model = AuthUserModel.fromMap({
      'id': 'user-id',
      'full_name': null,
      'role': ' Siswa ',
    }, 'siswa@example.com');

    expect(model.name, '-');
    expect(model.role, 'student');
  });
}
