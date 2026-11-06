import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/navigation/app_bar.dart';

class AdminMaterialDetailPage extends StatefulWidget {
  const AdminMaterialDetailPage({super.key});

  @override
  State<AdminMaterialDetailPage> createState() =>
      _AdminMaterialDetailPageState();
}

class _AdminMaterialDetailPageState extends State<AdminMaterialDetailPage> {
  final _db = Supabase.instance.client;
  String? _materialId;
  Future<Map<String, dynamic>>? _material;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_materialId != null) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    _materialId = arguments is Map
        ? arguments['id']?.toString()
        : arguments?.toString();
    if (_materialId != null && _materialId!.isNotEmpty) {
      _material = _load();
    }
  }

  Future<Map<String, dynamic>> _load() async => Map<String, dynamic>.from(
    await _db
        .from('materials')
        .select('title, description, content')
        .eq('id', _materialId!)
        .single(),
  );

  void _reload() => setState(() => _material = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Detail Materi', showBack: true),
    body: _material == null
        ? const Center(child: Text('Materi tidak ditemukan.'))
        : FutureBuilder<Map<String, dynamic>>(
            future: _material,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Materi belum dapat dimuat.\n${snapshot.error}'),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }

              final material = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (material['title'] ?? '-').toString(),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((material['description'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        material['description'].toString(),
                        style: const TextStyle(height: 1.6),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      (material['content'] ?? '').toString(),
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}
