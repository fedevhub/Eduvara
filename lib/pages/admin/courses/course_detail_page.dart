import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/navigation/app_bar.dart';
import '../../../components/course/course_header.dart';
import '../../../components/course/course_info.dart';
import '../../../components/course/course_material_list.dart';
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
          .from('course')
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

      final materials = (materialData as List).map((item) {
        final row = Map<String, dynamic>.from(item);

        return Materi(
          id: int.tryParse(row['id'].toString()) ?? 0,
          courseId: int.tryParse(id) ?? 0,
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
          CourseHeader(course: _course!),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SoftBtn.edit(onTap: _editCourse)),
              const SizedBox(width: 12),
              Expanded(child: SoftBtn.delete(onTap: _deleteCourse)),
            ],
          ),
          const SizedBox(height: 18),
          CourseInfo(course: _course!),
          const SizedBox(height: 22),
          const Text(
            'Materi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_materials.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada materi untuk course ini.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            CourseMaterialList(
              materials: _materials,
              onTap: (materi) {
                // Hubungkan ke halaman detail materi
                // setelah route detail materi tersedia.
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EduvaraAppBar(title: 'Detail Course', showBack: true),
      body: _buildContent(),
    );
  }
}
