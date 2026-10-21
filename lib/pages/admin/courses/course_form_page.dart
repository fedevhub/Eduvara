import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';

class AdminCourseFormPage extends StatefulWidget {
  const AdminCourseFormPage({super.key});

  @override
  State<AdminCourseFormPage> createState() => _AdminCourseFormPageState();
}

class _AdminCourseFormPageState extends State<AdminCourseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final name = TextEditingController();
  final desc = TextEditingController();
  final level = TextEditingController();

  // Pilihan tetap form (bukan data transaksi), jadi tidak butuh tabel.
  static const List<String> _baseSubjects = [
    'Matematika',
    'Bahasa Indonesia',
    'KIK',
    'Agama',
    'Pendidikan Pancasila / Kewarganegaraan',
    'Ilmu Pengetahuan Alam',
    'Ilmu Pengetahuan Sosial',
    'Bahasa Inggris',
  ];

  static const List<String> _baseLevels = [
    'Kelas 7',
    'Kelas 8',
    'Kelas 9',
    'Kelas 10',
    'Kelas 11',
    'Kelas 12',
  ];

  List<String> _subjects = List.of(_baseSubjects);
  List<String> _levels = List.of(_baseLevels);

  String? subject;
  String? teacherId;
  String? _editingCourseId;

  bool active = true;
  bool _init = false;
  bool _showErrors = false;
  bool _loading = true;
  bool _saving = false;
  String _studentQuery = '';

  final Set<String> selectedStudents = {};

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _editingCourse;

  List<Map<String, dynamic>> get availableTeachers => _teachers;

  List<Map<String, dynamic>> get availableStudents => _students;

  List<Map<String, dynamic>> get filteredStudents {
    final query = _studentQuery.trim().toLowerCase();

    if (query.isEmpty) return availableStudents;

    return availableStudents.where((user) {
      final fullName =
          (user['full_name'] ?? '').toString().toLowerCase();

      final detail =
          (user['class_name'] ?? user['grade_level'] ?? '')
              .toString()
              .toLowerCase();

      return fullName.contains(query) || detail.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    name.addListener(_onFieldChanged);
    level.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_showErrors && mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_init) return;
    _init = true;

    // Page lain cukup mengirim id course (String) atau Map yang berisi 'id'.
    // Data lengkapnya selalu diambil ulang dari Supabase.
    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg is String && arg.isNotEmpty) {
      _editingCourseId = arg;
    } else if (arg is Map && arg['id'] != null) {
      _editingCourseId = arg['id'].toString();
    }

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final profiles = List<Map<String, dynamic>>.from(
        await _db
            .from('profiles')
            .select('id, full_name, role, created_at')
            .inFilter('role', ['teacher', 'student'])
            .order('full_name'),
      );

      final subjects = List<String>.of(_baseSubjects);
      final levels = List<String>.of(_baseLevels);

      if (_editingCourseId != null) {
        await _loadCourse();
        await _loadCourseEnrollments();
      }

      // Pastikan nilai course lama tetap muncul di pilihan.
      if (level.text.isNotEmpty && !levels.contains(level.text)) {
        levels.add(level.text);
      }
      if (subject != null && !subjects.contains(subject)) {
        subjects.add(subject!);
      }

      if (!mounted) return;

      setState(() {
        _teachers = profiles
            .where((row) => (row['role'] ?? '').toString() == 'teacher')
            .toList();

        _students = profiles
            .where((row) => (row['role'] ?? '').toString() == 'student')
            .toList();

        _subjects = subjects;
        _levels = levels;

        if (teacherId != null &&
            !_teachers.any((user) => user['id'].toString() == teacherId)) {
          teacherId = null;
        }

        _loading = false;
      });
    } catch (e) {
      debugPrint('[CourseForm] Gagal memuat data: $e');

      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage(
        'Gagal mengambil data dari Supabase. '
        'Periksa tabel profiles, courses, enrollments, '
        'dan kebijakan RLS.\n$e',
      );
    }
  }

  Future<void> _loadCourse() async {
    final data = await _db
        .from('courses')
        .select()
        .eq('id', _editingCourseId!)
        .single();

    _editingCourse = data;

    name.text = (data['title'] ?? data['name'] ?? '').toString();
    desc.text = (data['description'] ?? '').toString();
    level.text = (data['grade_level'] ?? data['level'] ?? '').toString();
    subject = data['subject']?.toString();
    teacherId = (data['teacher_id'] ?? data['pengajar_id'])?.toString();

    final status = data['status'];
    active = status == true ||
        status?.toString().toLowerCase() == 'active' ||
        status?.toString().toLowerCase() == 'aktif';
  }

  Future<void> _loadCourseEnrollments() async {
    final rows = await _db
        .from('enrollments')
        .select('student_id')
        .eq('course_id', _editingCourseId!);

    selectedStudents
      ..clear()
      ..addAll(
        List<Map<String, dynamic>>.from(rows)
            .map((row) => row['student_id'].toString()),
      );
  }

  @override
  void dispose() {
    name.removeListener(_onFieldChanged);
    level.removeListener(_onFieldChanged);

    name.dispose();
    desc.dispose();
    level.dispose();

    super.dispose();
  }

  String? _validateName() {
    if (name.text.trim().isEmpty) {
      return 'Nama course wajib diisi';
    }

    return null;
  }

  String? _validateLevel() {
    if (level.text.trim().isEmpty) {
      return 'Tingkat kelas wajib diisi';
    }

    return null;
  }

  String? _validateSubject() {
    if (subject == null || subject!.isEmpty) {
      return 'Mata pelajaran wajib dipilih';
    }

    return null;
  }

  String? _validateTeacher() {
    if (teacherId == null || teacherId!.isEmpty) {
      return 'Guru pengajar wajib dipilih';
    }

    return null;
  }

  String? _validateStudents() {
    if (selectedStudents.isEmpty) {
      return 'Pilih minimal satu siswa';
    }

    return null;
  }

  Widget _errorText(String? message) {
    if (!_showErrors || message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 3),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 11,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveCourse() async {
    setState(() => _showErrors = true);

    final hasError = _validateName() != null ||
        _validateLevel() != null ||
        _validateSubject() != null ||
        _validateTeacher() != null ||
        _validateStudents() != null;

    if (hasError || _saving) return;

    setState(() => _saving = true);

    try {
      final courseData = <String, dynamic>{
        'title': name.text.trim(),
        'subject': subject,
        'description': desc.text.trim(),
        'grade_level': level.text.trim(),
        'teacher_id': teacherId,
        'status': active ? 'active' : 'inactive',
      };

      String courseId;

      if (_editingCourseId == null) {
        final inserted = await _db
            .from('courses')
            .insert(courseData)
            .select('id')
            .single();

        courseId = inserted['id'].toString();
      } else {
        await _db
            .from('courses')
            .update(courseData)
            .eq('id', _editingCourseId!);

        courseId = _editingCourseId!;
      }

      // Sinkronkan siswa: hapus yang dilepas, tambah yang baru saja.
      final existing = await _db
          .from('enrollments')
          .select('student_id')
          .eq('course_id', courseId);

      final existingIds = List<Map<String, dynamic>>.from(existing)
          .map((row) => row['student_id'].toString())
          .toSet();

      final toRemove = existingIds.difference(selectedStudents).toList();
      final toAdd = selectedStudents.difference(existingIds);

      if (toRemove.isNotEmpty) {
        await _db
            .from('enrollments')
            .delete()
            .eq('course_id', courseId)
            .inFilter('student_id', toRemove);
      }

      if (toAdd.isNotEmpty) {
        await _db.from('enrollments').insert(
              toAdd
                  .map((id) => <String, dynamic>{
                        'course_id': courseId,
                        'student_id': id,
                      })
                  .toList(),
            );
      }

      if (!mounted) return;

      await showSuccessDialog(
        context,
        _editingCourseId == null
            ? 'Course berhasil ditambahkan!'
            : 'Course berhasil diperbarui!',
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[CourseForm] Gagal menyimpan course: $e');

      _showMessage(
        'Gagal menyimpan course ke Supabase. '
        'Periksa nama kolom dan kebijakan RLS.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final edit = _editingCourseId != null;

    final nameError = _validateName();
    final levelError = _validateLevel();
    final subjectError = _validateSubject();
    final teacherError = _validateTeacher();
    final studentsError = _validateStudents();

    return EduScaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 6),

            Text(
              edit ? 'Edit Course' : 'Tambah Course',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              FormCard(
                children: [
                  const FieldLabel(
                    'Nama Course',
                    required: true,
                  ),

                  EduField(
                    controller: name,
                    hint: 'Masukkan nama course',
                    error: _showErrors && nameError != null,
                  ),

                  _errorText(nameError),

                  const FieldLabel(
                    'Mata Pelajaran',
                    required: true,
                  ),

                  SearchableSelect(
                    hint: 'Pilih mata pelajaran',
                    value: subject,
                    items: _subjects,
                    error: _showErrors && subjectError != null,
                    onChanged: (value) {
                      setState(() => subject = value);
                    },
                  ),

                  _errorText(subjectError),

                  const FieldLabel('Deskripsi'),

                  EduField(
                    controller: desc,
                    hint: 'Masukkan deskripsi course',
                    maxLines: 3,
                  ),

                  const FieldLabel(
                    'Tingkat Kelas',
                    required: true,
                  ),

                  EduSelect(
                    hint: 'Pilih tingkat kelas',
                    value: level.text.isEmpty ? null : level.text,
                    items: _levels,
                    error: _showErrors && levelError != null,
                    onChanged: (value) {
                      setState(() => level.text = value ?? '');
                    },
                  ),

                  _errorText(levelError),

                  const FieldLabel(
                    'Guru Pengajar',
                    required: true,
                  ),

                  SearchableSelect(
                    hint: 'Pilih guru pengajar',
                    value: _selectedTeacherName(),
                    items: availableTeachers
                        .map(
                          (user) =>
                              (user['full_name'] ?? '').toString(),
                        )
                        .where((value) => value.isNotEmpty)
                        .toList(),
                    subtitle: (teacherName) => 'Guru pengajar',
                    error: _showErrors && teacherError != null,
                    onChanged: (value) {
                      setState(() {
                        final matches = availableTeachers.where(
                          (row) =>
                              (row['full_name'] ?? '').toString() ==
                              value,
                        );

                        teacherId = matches.isEmpty
                            ? null
                            : matches.first['id'].toString();
                      });
                    },
                  ),

                  _errorText(teacherError),

                  const FieldLabel(
                    'Pilih Siswa',
                    required: true,
                  ),

                  if (availableStudents.isEmpty)
                    const Text(
                      'Belum ada siswa di Supabase. '
                      'Tambahkan akun siswa terlebih dahulu.',
                      style: TextStyle(
                        color: Ui.muted,
                        fontSize: 11,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _showErrors && studentsError != null
                                  ? Ui.red
                                  : Ui.line,
                          width:
                              _showErrors && studentsError != null
                                  ? 1.3
                                  : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedStudents.length} siswa dipilih',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            onChanged: (value) {
                              setState(() => _studentQuery = value);
                            },
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              hintText:
                                  'Cari nama atau kelas siswa',
                              hintStyle: TextStyle(fontSize: 10),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 18,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 6),

                          if (filteredStudents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              child: Text(
                                'Siswa tidak ditemukan.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Ui.muted,
                                ),
                              ),
                            )
                          else
                            for (final user in filteredStudents)
                              CheckboxListTile(
                                value: selectedStudents.contains(
                                  user['id'].toString(),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  (user['full_name'] ?? 'Tanpa nama')
                                      .toString(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                subtitle: Text(
                                  (user['class_name'] ??
                                          user['grade_level'] ??
                                          'Siswa')
                                      .toString(),
                                  style: const TextStyle(fontSize: 9),
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    final id = user['id'].toString();

                                    if (checked == true) {
                                      selectedStudents.add(id);
                                    } else {
                                      selectedStudents.remove(id);
                                    }
                                  });
                                },
                              ),
                        ],
                      ),
                    ),

                  _errorText(
                    availableStudents.isEmpty ? null : studentsError,
                  ),

                  const FieldLabel(
                    'Status',
                    required: true,
                  ),

                  StatusRadio(
                    active: active,
                    onChanged: (value) {
                      setState(() => active = value);
                    },
                  ),

                  const SizedBox(height: 18),

                  SolidBtn(
                    label: _saving
                        ? 'Menyimpan...'
                        : edit
                            ? 'Simpan Perubahan'
                            : 'Tambah Course',
                    onTap: _saveCourse,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            const EduFooter(),
          ],
        ),
      ),
    );
  }

  String? _selectedTeacherName() {
    if (teacherId == null) return null;

    for (final user in availableTeachers) {
      if (user['id'].toString() == teacherId) {
        return (user['full_name'] ?? '').toString();
      }
    }

    return null;
  }
}

class SearchableSelect extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String item)? subtitle;
  final bool error;

  const SearchableSelect({
    super.key,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.error = false,
  });

  Future<void> _showOptions(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SearchableOptionsSheet(
        title: hint,
        items: items,
        subtitle: subtitle,
        selectedValue: value,
      ),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = error ? Ui.red : Ui.line;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _showOptions(context),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: error ? 1.3 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: value == null ? 11 : 12,
                    color: value == null
                        ? const Color(0xFFB6BFCC)
                        : Ui.text,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Ui.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchableOptionsSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? Function(String item)? subtitle;
  final String? selectedValue;

  const _SearchableOptionsSheet({
    required this.title,
    required this.items,
    required this.subtitle,
    required this.selectedValue,
  });

  @override
  State<_SearchableOptionsSheet> createState() =>
      _SearchableOptionsSheetState();
}

class _SearchableOptionsSheetState
    extends State<_SearchableOptionsSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();

    final filteredItems = widget.items.where((item) {
      final detail = widget.subtitle?.call(item) ?? '';

      return item.toLowerCase().contains(normalizedQuery) ||
          detail.toLowerCase().contains(normalizedQuery);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                autofocus: true,
                onChanged: (value) {
                  setState(() => query = value);
                },
                decoration: const InputDecoration(
                  hintText: 'Cari pilihan',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(
                        child: Text('Pilihan tidak ditemukan.'),
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final detail = widget.subtitle?.call(item);

                          return ListTile(
                            title: Text(item),
                            subtitle:
                                detail == null ? null : Text(detail),
                            trailing: item == widget.selectedValue
                                ? const Icon(
                                    Icons.check,
                                    color: Ui.blue,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context, item);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}