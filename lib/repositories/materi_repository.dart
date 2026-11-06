import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/materi_model.dart';

class MateriRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Materi>> getByCourse(String courseId) async {
    final rows = await _db
        .from('materials')
        .select('id, course_id, title, content')
        .eq('course_id', courseId)
        .order('order_no');

    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => Materi(
            id: row['id'].toString(),
            courseId: row['course_id'].toString(),
            title: (row['title'] ?? '').toString(),
            content: (row['content'] ?? '').toString(),
          ),
        )
        .toList();
  }
}
