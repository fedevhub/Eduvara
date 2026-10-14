import '../models/quiz_model.dart';
import '../models/soal_quiz_model.dart';

class QuizRepository {
  Future<List<Quiz>> getQuizzes() async => const [
    Quiz(
      id: 1,
      courseId: 1,
      title: 'Quiz Pengenalan Aljabar',
      questionCount: 5,
    ),
    Quiz(id: 2, courseId: 2, title: 'Quiz Eksponen', questionCount: 5),
  ];

  Future<List<SoalQuiz>> getQuestions(int quizId) async => const [
    SoalQuiz(
      id: 1,
      quizId: 1,
      question: 'Bentuk sederhana dari 2x + 3x adalah ...',
      options: ['5x', '6x', '5', 'x'],
    ),
    SoalQuiz(
      id: 2,
      quizId: 1,
      question: 'Jika x = 2, maka 3x adalah ...',
      options: ['3', '5', '6', '9'],
    ),
  ];
}
