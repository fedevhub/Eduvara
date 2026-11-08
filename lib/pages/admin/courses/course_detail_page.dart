import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/navigation/app_bar.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';
import '../../../models/course_model.dart';
import '../../../models/materi_model.dart';

class AdminCourseDetailPage extends StatefulWidget {
  const AdminCourseDetailPage({super.key});

  @override
  State<AdminCourseDetailPage> createState() => _AdminCourseDetailPageState();
}

class _AdminCourseDetailPageState extends State<AdminCourseDetailPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _courseId;
  bool _initialized = false;
  bool _isLoading = true;

  String? _errorMessage;
  Course? _course;
  List<Materi> _materials = [];
  List<Map<String, dynamic>> _quizzes = [];
  String _subject = '-';
  String _gradeLevel = '-';
  List<Map<String, String>> _students = [];
  int _percent = 0;
  int _tab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is String || arguments is int) {
      _courseId = arguments.toString();
    } else if (arguments is Map && arguments['id'] != null) {
      _courseId = arguments['id'].toString();
    }

    _fetchCourseDetail();
  }

  Future<void> _editCourse() async {
    final changed = await Navigator.pushNamed(
      context,
      RouteNames.adminCourseForm,
      arguments: _courseId,
    );
    if (changed == true) await _fetchCourseDetail();
  }

  Future<void> _deleteCourse() async {
    final course = _course;
    final id = _courseId;
    if (course == null || id == null || id.isEmpty) {
      _showMessage('ID course tidak valid.');
      return;
    }

    final confirmed = await showConfirmDanger(
      context,
      title: 'Hapus Course?',
      message: '${course.title} akan dihapus dari platform.',
    );
    if (!confirmed || !mounted) return;

    try {
      await _supabase.rpc('admin_delete_course', params: {'p_course_id': id});
      if (!mounted) return;
      await showSuccessDialog(context, 'Course berhasil dihapus!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Gagal menghapus course: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchCourseDetail() async {
    final id = _courseId;

    if (id == null || id.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'ID course tidak ditemukan. Silakan pilih course terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Mengambil data course dari Supabase.
      final courseData = await _supabase
          .from('courses')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (courseData == null) {
        throw Exception('Data course tidak ditemukan.');
      }

      // 2. Mengambil nama pengajar dari profiles.
      String teacherName = '-';

      final teacherId = (courseData['teacher_id'] ?? courseData['pengajar_id'])
          ?.toString();

      if (teacherId != null && teacherId.isNotEmpty) {
        final teacherData = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', teacherId)
            .maybeSingle();

        teacherName = (teacherData?['full_name'] ?? '-').toString();
      }

      // 3. Mengambil materi berdasarkan course_id.
      final materialData = await _supabase
          .from('materials')
          .select()
          .eq('course_id', id);

      final enrollmentData = await _supabase
          .from('enrollments')
          .select('student_id')
          .eq('course_id', id);
      final studentIds = enrollmentData
          .map((row) => row['student_id']?.toString())
          .whereType<String>()
          .where((studentId) => studentId.isNotEmpty)
          .toSet()
          .toList();
      final studentNames = <String, String>{};
      if (studentIds.isNotEmpty) {
        final profiles = await _supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', studentIds);
        for (final profile in profiles) {
          studentNames[profile['id'].toString()] =
              (profile['full_name'] ?? 'Tanpa nama').toString();
        }
      }

      final studentAccounts = studentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _supabase
                  .from('user')
                  .select('id_user, kelas')
                  .inFilter('id_user', studentIds),
            );
      final studentClasses = {
        for (final account in studentAccounts)
          account['id_user'].toString(): (account['kelas'] ?? '-').toString(),
      };

      var completionRate = 0;
      if (studentIds.isNotEmpty && materialData.isNotEmpty) {
        final progress = await _supabase
            .from('material_progress')
            .select('material_id')
            .eq('completed', true)
            .inFilter('user_id', studentIds)
            .inFilter(
              'material_id',
              materialData.map((row) => row['id']).toList(),
            );
        completionRate =
            (progress.length / (studentIds.length * materialData.length) * 100)
                .round()
                .clamp(0, 100);
      }

      final quizData = List<Map<String, dynamic>>.from(
        await _supabase
            .from('quizzes')
            .select()
            .eq('course_id', id)
            .order('order_no'),
      );

      final students =
          studentIds
              .map(
                (studentId) => {
                  'name': studentNames[studentId] ?? 'Tanpa nama',
                  'class_name': studentClasses[studentId] ?? '-',
                },
              )
              .toList()
            ..sort(
              (a, b) =>
                  a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
            );

      final materials = (materialData as List).map((item) {
        final row = Map<String, dynamic>.from(item);

        return Materi(
          id: row['id'].toString(),
          courseId: id,
          title: (row['title'] ?? '').toString(),
          content: (row['content'] ?? '').toString(),
        );
      }).toList();

      // 4. Menyesuaikan data Supabase dengan model Course.
      final course = Course(
        id: id,
        title: (courseData['title'] ?? courseData['name'] ?? '').toString(),
        description: (courseData['description'] ?? '').toString(),
        teacher: teacherName,
        status: (courseData['status'] ?? 'active').toString(),
      );

      if (!mounted) return;

      setState(() {
        _course = course;
        _materials = materials;
        _subject = (courseData['subject'] ?? courseData['mapel'] ?? '-')
            .toString();
        _gradeLevel = (courseData['grade_level'] ?? courseData['level'] ?? '-')
            .toString();
        _students = students;
        _quizzes = quizData;
        _percent = completionRate;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('[CourseDetail] Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal mengambil data dari Supabase.\n$e';
      });
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Course tidak ditemukan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchCourseDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _course == null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _fetchCourseDetail,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _courseHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SoftBtn.edit(onTap: _editCourse)),
              const SizedBox(width: 12),
              Expanded(child: SoftBtn.delete(onTap: _deleteCourse)),
            ],
          ),
          const SizedBox(height: 12),
          _courseSummary(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatBox(value: '${_materials.length}', label: 'Materi'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(value: '${_quizzes.length}', label: 'Quiz'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(value: '$_percent%', label: 'Selesai'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegTabs(
            labels: const ['Daftar Siswa', 'Materi'],
            index: _tab,
            onChanged: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 12),
          if (_tab == 0) ..._studentTab(),
          if (_tab == 1) ..._materialTab(),
        ],
      ),
    );
  }

  Widget _courseHeader() => EduCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Ui.blueTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Ui.blue, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _course!.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_course!.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _course!.description,
                  style: const TextStyle(fontSize: 10, color: Ui.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _courseSummary() => EduCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _courseFact(
                Icons.person_outline,
                'Pengajar',
                _course!.teacher,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _courseFact(
                Icons.check_circle_outline,
                'Status',
                _course!.status,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        Row(
          children: [
            Expanded(
              child: _courseFact(
                Icons.menu_book_outlined,
                'Mata Pelajaran',
                _subject,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _courseFact(
                Icons.groups_outlined,
                'Jumlah Siswa',
                '${_students.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _courseFact(Icons.school_outlined, 'Kelas', _gradeLevel),
        ),
      ],
    ),
  );

  Widget _courseFact(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 19, color: Ui.navy),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Ui.muted)),
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );

  List<Widget> _studentTab() => [
    if (_students.isEmpty) _empty('Belum ada siswa pada course ini.'),
    if (_students.isNotEmpty)
      EduCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            for (var index = 0; index < _students.length; index++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: index == _students.length - 1
                      ? null
                      : const Border(bottom: BorderSide(color: Ui.line)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Ui.blueTint,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Ui.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _students[index]['name']!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _students[index]['class_name'] == '-'
                                ? 'Kelas -'
                                : _students[index]['class_name']!,
                            style: const TextStyle(
                              fontSize: 9,
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
        ),
      ),
  ];

  List<Widget> _materialTab() => [
    if (_materials.isEmpty) _empty('Belum ada materi untuk course ini.'),
    for (var index = 0; index < _materials.length; index++)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Ui.blueTint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Ui.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _materials[index].title.isEmpty
                          ? 'Materi ${index + 1}'
                          : _materials[index].title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _materials[index].content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8.5, color: Ui.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
  ];

  Widget _empty(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: Ui.muted),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EduvaraAppBar(title: 'Detail Course', showBack: true),
      body: _buildContent(),
    );
  }
}
