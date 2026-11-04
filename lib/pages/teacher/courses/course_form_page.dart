import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/forms/course_form.dart';

class TeacherCourseFormPage extends StatefulWidget {
  const TeacherCourseFormPage({super.key});
  @override
  State<TeacherCourseFormPage> createState() => _TeacherCourseFormPageState();
}

class _TeacherCourseFormPageState extends State<TeacherCourseFormPage> {
  // Samakan dengan nama tabel di database
  static const _tCourses = 'courses';
  static const _tEnrollments = 'enrollments';

  final _db = Supabase.instance.client;
  bool _saving = false;

  Future<void> _submit(dynamic data, dynamic students) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login tidak ditemukan';

      final form = Map<String, dynamic>.from(data as Map);

      // 1) Simpan course, teacher_id otomatis guru yang login
      final course = await _db
          .from(_tCourses)
          .insert({
            'title': form['title'],
            'subject': form['subject'],
            'description': form['description'],
            'grade_level': form['grade_level'],
            'teacher_id': uid,
            'status': form['status'] ?? 'active',
          })
          .select('id')
          .single();

      // 2) Daftarkan siswa yang dipilih (kalau ada)
      final ids = (students as Iterable?)?.map((e) => e.toString()).toList() ??
          <String>[];
      if (ids.isNotEmpty) {
        await _db.from(_tEnrollments).insert([
          for (final sid in ids)
            {'course_id': course['id'], 'student_id': sid},
        ]);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course berhasil ditambahkan')),
      );
      Navigator.pop(context, true); // true = ada data baru, list perlu refresh
    } catch (e) {
      debugPrint('TeacherCourseFormPage error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan course: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Tambah Course', showBack: true),
    body: Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AbsorbPointer(
            absorbing: _saving,
            child: CourseForm(onSubmit: _submit),
          ),
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}