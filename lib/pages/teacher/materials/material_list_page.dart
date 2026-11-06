import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/cards/material_card.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/materi_model.dart';

class TeacherMaterialListPage extends StatefulWidget {
  const TeacherMaterialListPage({super.key});

  @override
  State<TeacherMaterialListPage> createState() =>
      _TeacherMaterialListPageState();
}

class _TeacherMaterialListPageState extends State<TeacherMaterialListPage> {
  final _db = Supabase.instance.client;
  late Future<List<Materi>> _materials;

  @override
  void initState() {
    super.initState();
    _materials = _load();
  }

  Future<List<Materi>> _load() async {
    final teacherId = _db.auth.currentUser?.id;
    if (teacherId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final courses = await _db
        .from('courses')
        .select('id')
        .eq('teacher_id', teacherId);
    final courseIds = courses.map((row) => row['id']).toList();
    if (courseIds.isEmpty) return const [];

    final rows = await _db
        .from('materials')
        .select('id, course_id, title, content')
        .inFilter('course_id', courseIds)
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
            child: Text('Materi belum dapat dimuat.\n${snapshot.error}'),
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
                trailing: IconButton(
                  tooltip: 'Lihat materi',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.teacherMaterialDetail,
                    arguments: {'id': material.id},
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                ),
              ),
          ],
        );
      },
    ),
  );
}
