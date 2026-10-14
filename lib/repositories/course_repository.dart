import '../models/course_model.dart';

class CourseRepository {
  Future<List<Course>> getCourses() async => const [
    Course(
      id: 1,
      title: 'Pengenalan Aljabar',
      description: 'Konsep dasar aljabar dan bentuk aljabar.',
      teacher: 'Bu Eduvara',
    ),
    Course(
      id: 2,
      title: 'Eksponen',
      description: 'Memahami pangkat, sifat, dan penerapannya.',
      teacher: 'Pak Eduvara',
    ),
    Course(
      id: 3,
      title: 'Teks Narasi',
      description: 'Belajar struktur dan unsur teks narasi.',
      teacher: 'Bu Eduvara',
    ),
  ];
}
