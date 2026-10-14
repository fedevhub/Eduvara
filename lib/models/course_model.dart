class Course {
  final int id;
  final String title;
  final String description;
  final String teacher;
  final String status;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    this.teacher = '',
    this.status = 'Aktif',
  });
}
