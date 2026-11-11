import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';

class AdminCourseFormPage extends StatefulWidget {
  const AdminCourseFormPage({super.key});

  @override
  State<AdminCourseFormPage> createState() => _AdminCourseFormPageState();
}

class _AdminCourseFormPageState extends State<AdminCourseFormPage> {
  static const int _studentsPerPage = 7;

  // Isi daftar ini saat pilihan filter kelas dan jurusan sudah ditentukan.
  static const List<String> _studentClassFilters = [];
  static const List<String> _studentMajorFilters = [];

  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _db = Supabase.instance.client;

  final name = TextEditingController();
  final desc = TextEditingController();
  final level = TextEditingController();

  static const List<String> _baseLevels = [
    'Kelas 7',
    'Kelas 8',
    'Kelas 9',
    'Kelas 10',
    'Kelas 11',
    'Kelas 12',
  ];

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
  String? _selectedStudentClass;
  String? _selectedStudentMajor;
  String _studentNameOrder = 'Nama A-Z';
  int _studentPage = 0;

  final Set<String> selectedStudents = {};

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];

  List<Map<String, dynamic>> get availableTeachers => _teachers;

  List<Map<String, dynamic>> get availableStudents => _students;

  bool _isActiveAccount(Map<String, dynamic>? account) {
    final status = account?['status'];
    if (status == null) return true;
    return const {
      'active',
      'aktif',
      'true',
      '1',
    }.contains(status.toString().trim().toLowerCase());
  }

  List<Map<String, dynamic>> get filteredStudents {
    final query = _studentQuery.trim().toLowerCase();
    final students = availableStudents.where((user) {
      final fullName = (user['full_name'] ?? '').toString().toLowerCase();
      final className = _className(user).toLowerCase();
      final major = _majorForStudent(user).toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          fullName.contains(query) ||
          className.contains(query) ||
          major.contains(query);
      final matchesClass =
          _selectedStudentClass == null ||
          _className(user) == _selectedStudentClass;
      final matchesMajor =
          _selectedStudentMajor == null ||
          _majorForStudent(user).toUpperCase() ==
              _selectedStudentMajor!.toUpperCase();
      return matchesSearch && matchesClass && matchesMajor;
    }).toList();

    students.sort((first, second) {
      final byName = _studentName(
        first,
      ).toLowerCase().compareTo(_studentName(second).toLowerCase());
      return _studentNameOrder == 'Nama Z-A' ? -byName : byName;
    });

    return students;
  }

  int get _studentPageCount =>
      (filteredStudents.length / _studentsPerPage).ceil().clamp(1, 1 << 31);

  List<Map<String, dynamic>> get _studentsOnCurrentPage {
    final start = _studentPage * _studentsPerPage;
    if (start >= filteredStudents.length) return const [];
    final end = (start + _studentsPerPage).clamp(0, filteredStudents.length);
    return filteredStudents.sublist(start, end);
  }

  String _studentName(Map<String, dynamic> student) =>
      (student['full_name'] ?? 'Tanpa nama').toString();

  String _className(Map<String, dynamic> student) =>
      (student['class_name'] ?? student['grade_level'] ?? 'Siswa').toString();

  String _majorForStudent(Map<String, dynamic> student) {
    final className = _className(student).trim();
    if (className.isEmpty || className == 'Siswa') return '-';

    const classLabels = {
      'KELAS',
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    };
    final majorParts = className.toUpperCase().split(RegExp(r'\s+')).where((
      part,
    ) {
      return !classLabels.contains(part) && !RegExp(r'^\d+$').hasMatch(part);
    });
    final major = majorParts.join(' ');
    return major.isEmpty ? '-' : major;
  }

  Widget _studentFilterDropdown({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Ui.muted),
      style: const TextStyle(fontSize: 14, color: Ui.text),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Ui.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Ui.blue, width: 1.5),
        ),
      ),
      hint: Text(hint, style: const TextStyle(fontSize: 14, color: Ui.text)),
      items: [
        DropdownMenuItem<String>(value: null, child: Text(hint)),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  void _updateStudentFilter(VoidCallback update) {
    setState(() {
      update();
      _studentPage = 0;
    });
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
      final userRows = List<Map<String, dynamic>>.from(
        await _db
            .from('user')
            .select('id_user, nama_lengkap, nip, kelas, status'),
      );
      final userDetails = {
        for (final row in userRows) row['id_user'].toString(): row,
      };
      final activeProfiles = profiles.where((row) {
        return _isActiveAccount(userDetails[row['id'].toString()]);
      }).toList();

      final levels = List<String>.of(_baseLevels);

      if (_editingCourseId != null) {
        await _loadCourse();
        await _loadCourseEnrollments();
      }

      // Pastikan nilai course lama tetap muncul di pilihan.
      if (level.text.isNotEmpty && !levels.contains(level.text)) {
        levels.add(level.text);
      }
      if (!mounted) return;

      setState(() {
        _teachers = activeProfiles
            .where((row) => (row['role'] ?? '').toString() == 'teacher')
            .map((row) {
              final details = userDetails[row['id'].toString()];
              return {
                ...row,
                'full_name': details?['nama_lengkap'] ?? row['full_name'],
                'nip': details?['nip'],
              };
            })
            .toList();

        _students = activeProfiles
            .where((row) => (row['role'] ?? '').toString() == 'student')
            .map((row) {
              final details = userDetails[row['id'].toString()];
              return {
                ...row,
                'full_name': details?['nama_lengkap'] ?? row['full_name'],
                'class_name': details?['kelas'] ?? 'Siswa',
              };
            })
            .toList();

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

    name.text = (data['title'] ?? data['name'] ?? '').toString();
    desc.text = (data['description'] ?? '').toString();
    level.text = (data['grade_level'] ?? data['level'] ?? '').toString();
    subject = data['subject']?.toString();
    teacherId = (data['teacher_id'] ?? data['pengajar_id'])?.toString();

    final status = data['status'];
    active =
        status == true ||
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
        List<Map<String, dynamic>>.from(
          rows,
        ).map((row) => row['student_id'].toString()),
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
        style: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveCourse() async {
    setState(() => _showErrors = true);

    final hasError =
        _validateName() != null ||
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

      await _db.rpc(
        'admin_save_course',
        params: {
          'p_course_id': _editingCourseId,
          'p_title': courseData['title'],
          'p_subject': courseData['subject'],
          'p_description': courseData['description'],
          'p_grade_level': courseData['grade_level'],
          'p_teacher_id': courseData['teacher_id'],
          'p_active': active,
          'p_student_ids': selectedStudents.toList(),
        },
      );

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              FormCard(
                children: [
                  const FieldLabel('Nama Course', required: true),

                  EduField(
                    controller: name,
                    hint: 'Masukkan nama course',
                    error: _showErrors && nameError != null,
                  ),

                  _errorText(nameError),

                  const FieldLabel('Mata Pelajaran', required: true),

                  SubjectSelector(
                    hint: 'Pilih mata pelajaran',
                    value: subject,
                    extraSubjects: subject == null ? const [] : [subject!],
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

                  const FieldLabel('Tingkat Kelas', required: true),

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

                  const FieldLabel('Guru Pengajar', required: true),

                  SearchableSelect(
                    hint: 'Pilih guru pengajar',
                    value: teacherId,
                    items: availableTeachers
                        .map((user) => user['id'].toString())
                        .toList(),
                    itemLabel: _teacherNameById,
                    subtitle: _teacherNipById,
                    error: _showErrors && teacherError != null,
                    onChanged: (value) {
                      setState(() => teacherId = value);
                    },
                  ),

                  _errorText(teacherError),

                  const FieldLabel('Pilih Siswa', required: true),

                  if (availableStudents.isEmpty)
                    const Text(
                      'Belum ada siswa di Supabase. '
                      'Tambahkan akun siswa terlebih dahulu.',
                      style: TextStyle(color: Ui.muted, fontSize: 11),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _showErrors && studentsError != null
                              ? Ui.red
                              : Ui.line,
                          width: _showErrors && studentsError != null ? 1.3 : 1,
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
                              _updateStudentFilter(() => _studentQuery = value);
                            },
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              hintText: 'Cari nama, kelas, atau jurusan siswa',
                              hintStyle: TextStyle(fontSize: 10),
                              prefixIcon: Icon(Icons.search, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Filter siswa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Ui.text,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: _studentFilterDropdown(
                                  hint: 'Kelas',
                                  value: _selectedStudentClass,
                                  options: _studentClassFilters,
                                  onChanged: (value) => _updateStudentFilter(
                                    () => _selectedStudentClass = value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _studentFilterDropdown(
                                  hint: 'Jurusan',
                                  value: _selectedStudentMajor,
                                  options: _studentMajorFilters,
                                  onChanged: (value) => _updateStudentFilter(
                                    () => _selectedStudentMajor = value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _studentFilterDropdown(
                                  hint: 'Urutkan nama',
                                  value: _studentNameOrder,
                                  options: const ['Nama A-Z', 'Nama Z-A'],
                                  onChanged: (value) => _updateStudentFilter(
                                    () =>
                                        _studentNameOrder = value ?? 'Nama A-Z',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          if (filteredStudents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Siswa tidak ditemukan.',
                                style: TextStyle(fontSize: 11, color: Ui.muted),
                              ),
                            )
                          else
                            for (final user in _studentsOnCurrentPage)
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
                                  '${_className(user)} • ${_majorForStudent(user)}',
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

                          if (filteredStudents.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Halaman ${_studentPage + 1} dari '
                                  '$_studentPageCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Ui.muted,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Halaman sebelumnya',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _studentPage == 0
                                      ? null
                                      : () => setState(() => _studentPage--),
                                ),
                                IconButton(
                                  tooltip: 'Halaman berikutnya',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed:
                                      _studentPage >= _studentPageCount - 1
                                      ? null
                                      : () => setState(() => _studentPage++),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                  _errorText(availableStudents.isEmpty ? null : studentsError),

                  const FieldLabel('Status', required: true),

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

  String _teacherNameById(String id) {
    for (final user in availableTeachers) {
      if (user['id'].toString() == id) {
        return (user['full_name'] ?? '').toString();
      }
    }

    return '';
  }

  String? _teacherNipById(String id) {
    for (final user in availableTeachers) {
      if (user['id'].toString() == id) {
        final nip = user['nip']?.toString().trim();
        return nip == null || nip.isEmpty ? null : 'NIP: $nip';
      }
    }

    return null;
  }
}

class SubjectSelector extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> extraSubjects;
  final ValueChanged<String?> onChanged;
  final bool error;

  const SubjectSelector({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.extraSubjects = const [],
    this.error = false,
  });

  static const List<String> _mainSubjects = [
    'Matematika',
    'Bahasa Indonesia',
    'KIK',
    'Agama',
    'Pendidikan Pancasila / Kewarganegaraan',
    'Ilmu Pengetahuan Alam',
    'Ilmu Pengetahuan Sosial',
    'Bahasa Inggris',
  ];

  static const Map<String, List<String>> _majorSubjects = {
    'RPL': ['Pemrograman'],
    'TKJ': ['Jaringan'],
    'Metro': ['Teknik Industri'],
    'Elin': ['Kelistrikan'],
  };

  @override
  Widget build(BuildContext context) => SearchableSelect(
    hint: hint,
    value: value,
    items: _mainSubjects,
    filters: _majorSubjects,
    extraItems: extraSubjects,
    error: error,
    onChanged: onChanged,
  );
}

class SearchableSelect extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final Map<String, List<String>>? filters;
  final List<String> extraItems;
  final String Function(String item)? itemLabel;
  final String? Function(String item)? subtitle;
  final bool error;

  const SearchableSelect({
    super.key,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.filters,
    this.extraItems = const [],
    this.itemLabel,
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
        filters: filters,
        extraItems: extraItems,
        itemLabel: itemLabel,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: error ? 1.3 : 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null ? hint : itemLabel?.call(value!) ?? value!,
                  style: TextStyle(
                    fontSize: value == null ? 11 : 12,
                    color: value == null ? const Color(0xFFB6BFCC) : Ui.text,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Ui.muted),
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
  final Map<String, List<String>>? filters;
  final List<String> extraItems;
  final String Function(String item)? itemLabel;
  final String? Function(String item)? subtitle;
  final String? selectedValue;

  const _SearchableOptionsSheet({
    required this.title,
    required this.items,
    required this.filters,
    required this.extraItems,
    required this.itemLabel,
    required this.subtitle,
    required this.selectedValue,
  });

  @override
  State<_SearchableOptionsSheet> createState() =>
      _SearchableOptionsSheetState();
}

class _SearchableOptionsSheetState extends State<_SearchableOptionsSheet> {
  String query = '';
  String? selectedFilter;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final filters = widget.filters;
    final List<String> filterItems;
    if (filters == null) {
      filterItems = widget.items;
    } else if (selectedFilter == null) {
      filterItems = [
        ...widget.items,
        ...filters.values.expand((subjects) => subjects),
      ];
    } else {
      filterItems = [...filters[selectedFilter] ?? const [], ...widget.items];
    }
    final items = {...filterItems, ...widget.extraItems}.toList();

    final filteredItems = items.where((item) {
      final label = widget.itemLabel?.call(item) ?? item;
      final detail = widget.subtitle?.call(item) ?? '';

      return label.toLowerCase().contains(normalizedQuery) ||
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
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),

              if (filters != null && filters.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: const Text('Mapel'),
                      selected: selectedFilter == null,
                      onSelected: (_) => setState(() => selectedFilter = null),
                    ),
                    for (final filter in filters.keys)
                      ChoiceChip(
                        label: Text(filter),
                        selected: selectedFilter == filter,
                        onSelected: (_) =>
                            setState(() => selectedFilter = filter),
                      ),
                  ],
                ),
              ],

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
                    ? const Center(child: Text('Pilihan tidak ditemukan.'))
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final label = widget.itemLabel?.call(item) ?? item;
                          final detail = widget.subtitle?.call(item);

                          return ListTile(
                            title: Text(label),
                            subtitle: detail == null ? null : Text(detail),
                            trailing: item == widget.selectedValue
                                ? const Icon(Icons.check, color: Ui.blue)
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
