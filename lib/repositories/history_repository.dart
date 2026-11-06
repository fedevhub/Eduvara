import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/history_model.dart';

class HistoryRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<History>> getHistory() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final rows = await _db
        .from('quiz_attempts')
        .select('id, score, total_points, created_at, quizzes(title)')
        .eq('user_id', userId)
        .eq('completed', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows).map((row) {
      final quiz = row['quizzes'] as Map?;
      final score = row['score'];
      final totalPoints = row['total_points'];
      final scoreText = score is num && totalPoints is num
          ? '${score.round()}/${totalPoints.round()} poin'
          : (score ?? 0).toString();
      return History(
        id: row['id'].toString(),
        activity: 'Menyelesaikan ${quiz?['title'] ?? 'Quiz'}',
        date: (row['created_at'] ?? '').toString(),
        status: 'Nilai $scoreText',
      );
    }).toList();
  }
}
