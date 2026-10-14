import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/course_model.dart';
import '../../../repositories/course_repository.dart';

enum _St { done, running, locked }

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});
  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  int filter = 0;
  String query = '';
  final CourseRepository _repository = CourseRepository();
  late Future<List<Course>> _courses;

  @override
  void initState() {
    super.initState();
    _courses = _repository.getCourses();
  }

  _St _status(int index, Course course) {
    final status = course.status.toLowerCase();
    if (status.contains('selesai') || index == 0) return _St.done;
    if (status.contains('kunci') || index > 1) return _St.locked;
    return _St.running;
  }

  bool _match(_St s) => switch (filter) {
    1 => s == _St.done, 2 => s == _St.running, 3 => s == _St.locked, _ => true,
  };

  Widget _card(Course course, _St st, int pct) {
    final color = switch (st) { _St.done => Ui.green, _St.running => Ui.blue, _St.locked => Ui.orange };
    final card = EduCard(
      borderColor: st == _St.locked ? null : color,
      padding: const EdgeInsets.all(12),
      onTap: st == _St.locked ? null : () => Navigator.pushNamed(context, RouteNames.studentCourseDetail, arguments: course.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(course.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
          Pill(switch (st) { _St.done => 'Selesai', _St.running => 'Berjalan', _St.locked => 'Terkunci' }, kind: switch (st) { _St.done => PillKind.done, _St.running => PillKind.running, _St.locked => PillKind.locked })]),
        Text('${course.teacher} • ${course.description}', style: const TextStyle(fontSize: 8.5)),
        if (st != _St.locked) ...[
          const SizedBox(height: 8),
          Text('$pct% ${st == _St.done ? 'Selesai' : 'Berjalan'}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 3), ProgressLine(value: pct / 100, color: color),
        ] else const SizedBox(height: 12),
      ]),
    );
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: st == _St.locked ? LockedCard(text: 'Selesaikan Course Sebelumnya', child: card) : card);
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'student', current: 1),
    body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 6),
      const Text('Manajemen Course', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      SearchBox(hint: 'Cari Course', pill: true, onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: 10),
      FilterChips(labels: const ['Semua', 'Selesai', 'Berjalan', 'Terkunci'], index: filter, onChanged: (i) => setState(() => filter = i)),
      const SizedBox(height: 12),
      FutureBuilder<List<Course>>(
        future: _courses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
          if (snapshot.hasError) return const Text('Course belum dapat dimuat. Coba buka kembali halaman ini.');
          final courses = snapshot.data ?? [];
          final visible = courses.asMap().entries.where((e) => _match(_status(e.key, e.value)) && e.value.title.toLowerCase().contains(query.toLowerCase())).toList();
          if (visible.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Course tidak ditemukan.'));
          return Column(children: [for (final e in visible) _card(e.value, _status(e.key, e.value), _status(e.key, e.value) == _St.done ? 100 : 60)]);
        },
      ),
    ]),
  );
}
