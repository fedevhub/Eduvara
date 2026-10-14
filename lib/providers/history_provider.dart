import 'package:flutter/foundation.dart';
import '../models/history_model.dart';
import '../repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository repository = HistoryRepository();
  List<History> items = [];
  Future<void> load() async {
    items = await repository.getHistory();
    notifyListeners();
  }
}
