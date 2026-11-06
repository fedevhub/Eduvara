class Quiz {
  final String id;
  final String courseId;
  final String title;
  final int questionCount;
  final int durationMinutes;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    this.questionCount = 0,
    this.durationMinutes = 0,
  });
}
