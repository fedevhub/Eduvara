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
  final _db = Supabase.instance.client;
  final _activityRepository = ActivityRepository();

  String? _materialId;
  String _materialTitle = '';
  Map<String, dynamic>? _material;
  bool _completed = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      _materialId = arguments['id']?.toString();
      _materialTitle = arguments['entity_name']?.toString() ?? '';
    } else if (arguments is String) {
      _materialTitle = arguments;
    }

    if (_materialId == null) {
      _loading = false;
      _error = 'Materi tidak ditemukan';
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

      Map<String, dynamic> material;
      try {
        material = Map<String, dynamic>.from(
          await _db.from('materials').select().eq('id', _materialId!).single(),
        );
      } on PostgrestException catch (e) {
        if (e.code != 'PGRST205') rethrow;
        throw 'Materi belum tersedia pada database.';
      }

      final progress = await _db
          .from('material_progress')
          .select('completed')
          .eq('user_id', uid)
          .eq('material_id', _materialId!)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _material = material;
        _materialTitle = _material!['title']?.toString() ?? _materialTitle;
        _completed = progress?['completed'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat materi: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markComplete() async {
    if (_saving || _completed || _materialId == null) return;
    setState(() => _saving = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login berakhir, silakan login ulang';

      // 1) simpan progress (dibaca halaman detail course)
      await _db.from('material_progress').upsert({
        'user_id': uid,
        'material_id': _materialId,
        'completed': true,
      }, onConflict: 'user_id,material_id');

      // 2) catat aktivitas untuk admin (gagal di sini tidak membatalkan progress)
      try {
        await _activityRepository.record(
          action: 'complete',
          entity: 'material',
          entityName: _materialTitle,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() => _completed = true);
      await showSuccessDialog(context, 'Materi berhasil ditandai selesai!');
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      _showError('Sesi login tidak valid: ${e.message}');
    } on PostgrestException catch (e) {
      _showError('Gagal menyimpan progress: ${e.message}');
    } catch (e) {
      _showError('Gagal menyimpan progress: $e');
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

  String _formatSize(dynamic raw) {
    final bytes = int.tryParse(raw?.toString() ?? '');
    if (bytes == null) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }

  String _fileType(String name) {
    final i = name.lastIndexOf('.');
    return i == -1 ? 'FILE' : name.substring(i + 1).toUpperCase();
  }

  List<Widget> _summaryParagraphs(String? summary) {
    final parts = (summary ?? '')
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return const [
        Text(
          'Belum ada ringkasan materi.',
          style: TextStyle(fontSize: 9, color: Ui.muted),
        ),
      ];
    }
    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 10));
      widgets.add(
        Text(parts[i], style: const TextStyle(fontSize: 9, height: 1.5)),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Ui.bg,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_error != null || _material == null) {
      return Scaffold(
        backgroundColor: Ui.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackLink(),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    _error ?? 'Data tidak tersedia',
                    style: const TextStyle(fontSize: 10, color: Ui.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _materialId == null ? null : _load,
                    child: const Text('Coba lagi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fileName = _material!['file_name']?.toString();
    final hasFile = fileName != null && fileName.isNotEmpty;
    final sizeText = _formatSize(_material!['file_size']);

    return Scaffold(
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
                  EduCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Materi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._summaryParagraphs(
                          [
                                _material!['summary'],
                                _material!['content'],
                                _material!['description'],
                              ]
                              .map((value) => value?.toString().trim() ?? '')
                              .firstWhere(
                                (value) => value.isNotEmpty,
                                orElse: () => '',
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (hasFile) ...[
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  sizeText.isEmpty
                                      ? _fileType(fileName)
                                      : '$sizeText • ${_fileType(fileName)}',
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    color: Ui.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 16,
              child: GestureDetector(
                onTap: (_saving || _completed) ? null : _markComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _completed ? Ui.greenDark : Ui.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _saving
                            ? 'Menyimpan...'
                            : (_completed ? 'Sudah Selesai' : 'Tandai Selesai'),
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
}
