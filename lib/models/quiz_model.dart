class Quiz {
  final int id;
  final int courseId;
  final String title;
  final int questionCount;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    this.questionCount = 0,
  });
}
