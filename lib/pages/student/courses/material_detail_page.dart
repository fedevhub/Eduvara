import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../repositories/activity_repository.dart';

class StudentMaterialDetailPage extends StatefulWidget {
  const StudentMaterialDetailPage({super.key});

  @override
  State<StudentMaterialDetailPage> createState() =>
      _StudentMaterialDetailPageState();
}

class _StudentMaterialDetailPageState extends State<StudentMaterialDetailPage> {
  final _activityRepository = ActivityRepository();
  String _materialTitle = 'Aljabar';
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map && arguments['entity_name'] != null) {
      _materialTitle = arguments['entity_name'].toString();
    } else if (arguments is String && arguments.isNotEmpty) {
      _materialTitle = arguments;
    }
  }

  Future<void> _markComplete() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _activityRepository.record(
        action: 'complete',
        entity: 'material',
        entityName: _materialTitle,
      );
      if (!mounted) return;
      await showSuccessDialog(context, 'Materi berhasil ditandai selesai!');
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      _showError('Sesi login tidak valid: ${e.message}');
    } catch (e) {
      _showError('Gagal mengirim aktivitas ke admin: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    body: SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackLink(),
                Text(
                  _materialTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const EduCard(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Materi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pengenalan Aljabar merupakan salah satu materi dasar dalam matematika yang mempelajari penggunaan angka, huruf, dan simbol untuk menyatakan suatu nilai atau hubungan matematika. Pemahaman tentang variabel, konstanta, koefisien, dan suku aljabar menjadi dasar penting untuk mempelajari materi matematika yang lebih lanjut.',
                        style: TextStyle(fontSize: 9, height: 1.5),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Dalam kehidupan sehari-hari, konsep aljabar dapat digunakan untuk menyelesaikan berbagai permasalahan, seperti menghitung jumlah barang, menentukan harga, atau mencari nilai yang belum diketahui. Oleh karena itu, penting untuk memahami bentuk aljabar, unsur-unsurnya, serta operasi dasar aljabar dengan benar.',
                        style: TextStyle(fontSize: 9, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                EduCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Ui.greenSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: Ui.greenDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Handout_pengenalan_teks_narasi.pdf',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '234 KB • PDF',
                              style: TextStyle(fontSize: 7.5, color: Ui.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 16,
            child: GestureDetector(
              onTap: _saving ? null : _markComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Ui.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _saving ? 'Menyimpan...' : 'Tandai Selesai',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
