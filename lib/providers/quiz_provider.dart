import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';
import '../models/soal_quiz_model.dart';
import '../repositories/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  final QuizRepository repository = QuizRepository();
  List<Quiz> items = [];
  List<SoalQuiz> questions = [];
  Future<void> load() async {
    items = await repository.getQuizzes();
    notifyListeners();
  }

  Future<void> loadQuestions(int id) async {
    questions = await repository.getQuestions(id);
    notifyListeners();
  }
}
