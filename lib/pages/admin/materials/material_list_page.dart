import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/cards/material_card.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/materi_model.dart';

class AdminMaterialListPage extends StatefulWidget {
  const AdminMaterialListPage({super.key});

  @override
  State<AdminMaterialListPage> createState() => _AdminMaterialListPageState();
}

class _AdminMaterialListPageState extends State<AdminMaterialListPage> {
  final _db = Supabase.instance.client;
  late Future<List<Materi>> _materials;

  @override
  void initState() {
    super.initState();
    _materials = _load();
  }

  Future<List<Materi>> _load() async {
    final rows = await _db
        .from('materials')
        .select('id, course_id, title, content')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(
          (row) => Materi(
            id: row['id'].toString(),
            courseId: row['course_id'].toString(),
            title: (row['title'] ?? '').toString(),
            content: (row['content'] ?? '').toString(),
          ),
        )
        .toList();
  }

  void _reload() => setState(() => _materials = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Materi'),
    body: FutureBuilder<List<Materi>>(
      future: _materials,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Materi belum dapat dimuat.\n${snapshot.error}'),
                TextButton(onPressed: _reload, child: const Text('Coba lagi')),
              ],
            ),
          );
        }

        final materials = snapshot.data ?? const <Materi>[];
        if (materials.isEmpty) {
          return const Center(child: Text('Belum ada materi.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final material in materials)
              MaterialCard(
                material: material,
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.adminMaterialDetail,
                  arguments: material.id,
                ),
              ),
          ],
        );
      },
    ),
  );
}
