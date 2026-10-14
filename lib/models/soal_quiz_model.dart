class SoalQuiz {
  final int id;
  final int quizId;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  const SoalQuiz({
    required this.id,
    required this.quizId,
    required this.question,
    required this.options,
    this.correctOptionIndex = 0,
  });
}
