import 'package:flutter/foundation.dart';
import '../models/materi_model.dart';
import '../repositories/materi_repository.dart';

class MateriProvider extends ChangeNotifier {
  final MateriRepository repository = MateriRepository();
  List<Materi> items = [];
  Future<void> load(int courseId) async {
    items = await repository.getByCourse(courseId);
    notifyListeners();
  }
}
