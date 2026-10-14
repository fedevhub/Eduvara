import '../models/materi_model.dart';

class MateriRepository {
  Future<List<Materi>> getByCourse(int courseId) async => [
    Materi(
      id: 1,
      courseId: courseId,
      title: 'Pengenalan Materi',
      content: 'Materi pembelajaran Eduvara.',
    ),
    Materi(
      id: 2,
      courseId: courseId,
      title: 'Materi Lanjutan',
      content: 'Pembahasan dan contoh soal.',
    ),
  ];
}
