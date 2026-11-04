import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model.dart';

class CourseRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Course>> getCourses() async {
    final studentId = _db.auth.currentUser?.id;
    if (studentId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final enrollmentRows = await _db
        .from('enrollments')
        .select('course_id')
        .eq('student_id', studentId);
    final courseIds = (enrollmentRows as List)
        .map((row) => row['course_id'])
        .where((id) => id != null)
        .toSet()
        .toList();
    if (courseIds.isEmpty) return const [];

    final courseRows = await _db
        .from('courses')
        .select(
          'id, title, description, subject, grade_level, teacher_id, status',
        )
        .inFilter('id', courseIds);
    final courses = List<Map<String, dynamic>>.from(courseRows);

    final teacherIds = courses
        .map((row) => row['teacher_id'])
        .where((id) => id != null)
        .toSet()
        .toList();
    final teacherNames = <String, String>{};
    if (teacherIds.isNotEmpty) {
      try {
        final teacherRows = await _db
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', teacherIds);
        for (final row in List<Map<String, dynamic>>.from(teacherRows)) {
          teacherNames[row['id'].toString()] = (row['full_name'] ?? '')
              .toString();
        }
      } on PostgrestException catch (e) {
        final message = e.message.toLowerCase();
        if (e.code != 'PGRST205' &&
            !message.contains('could not find the table')) {
          rethrow;
        }
      }
    }

    return courses.map((row) {
      return Course(
        id: row['id'].toString(),
        title: (row['title'] ?? '').toString(),
        description: (row['description'] ?? '').toString(),
        teacher: teacherNames[row['teacher_id']?.toString()] ?? '-',
        status: (row['status'] ?? 'active').toString(),
      );
    }).toList();
  }
}
