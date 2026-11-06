import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_model.dart';
import '../models/soal_quiz_model.dart';

class QuizRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Quiz>> getQuizzes() async {
    final rows = await _db
        .from('quizzes')
        .select('id, course_id, title, question_count')
        .eq('status', 'published')
        .order('order_no');

    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => Quiz(
            id: row['id'].toString(),
            courseId: row['course_id'].toString(),
            title: (row['title'] ?? '').toString(),
            questionCount: (row['question_count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<List<SoalQuiz>> getQuestions(String quizId) async {
    final rows = await _db.rpc(
      'get_student_quiz_questions',
      params: {'p_quiz_id': quizId},
    );
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => SoalQuiz(
            id: row['id'].toString(),
            quizId: quizId,
            question: (row['question'] ?? '').toString(),
            options: [
              row['option_a']?.toString() ?? '',
              row['option_b']?.toString() ?? '',
              row['option_c']?.toString() ?? '',
              row['option_d']?.toString() ?? '',
            ],
          ),
        )
        .toList();
  }
}
