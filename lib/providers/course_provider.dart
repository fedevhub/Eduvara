import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository repository = CourseRepository();
  List<Course> items = [];
  Future<void> load() async {
    items = await repository.getCourses();
    notifyListeners();
  }
}
