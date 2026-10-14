import '../models/history_model.dart';

class HistoryRepository {
  Future<List<History>> getHistory() async => const [
    History(
      id: 1,
      activity: 'Menyelesaikan Quiz Aljabar',
      date: '28 Sep 2026',
      status: 'Selesai',
    ),
    History(
      id: 2,
      activity: 'Membuka Materi Eksponen',
      date: '27 Sep 2026',
      status: 'Dilihat',
    ),
  ];
}
