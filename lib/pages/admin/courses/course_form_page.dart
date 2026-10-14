import 'package:flutter/material.dart';

import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';

class AdminCourseFormPage extends StatefulWidget {
  const AdminCourseFormPage({super.key});

  @override
  State<AdminCourseFormPage> createState() =>
      _AdminCourseFormPageState();
}

class _AdminCourseFormPageState extends State<AdminCourseFormPage> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final desc = TextEditingController();
  final level = TextEditingController();

  String? subject;
  String? teacher;

  bool active = true;
  bool _init = false;
  bool _showErrors = false;

  final Set<String> selectedStudents = {};

  MockCourse? _editingCourse;

  List<MockUser> get availableTeachers =>
      mockGuru.where((user) => user.active).toList();

  List<MockUser> get availableStudents =>
      mockSiswa.where((user) => user.active).toList();

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

    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg is MockCourse) {
      _editingCourse = arg;

      name.text = arg.title;
      desc.text = arg.description;
      level.text = arg.level;
      subject = arg.subject;
      active = arg.active;

      if (availableTeachers.any((u) => u.name == arg.teacher)) {
        teacher = arg.teacher;
      }

      selectedStudents.addAll(
        arg.studentNames.where(
          (studentName) =>
              availableStudents.any((user) => user.name == studentName),
        ),
      );
    }
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
    if (teacher == null || teacher!.isEmpty) {
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

  Future<void> _saveCourse() async {
    setState(() {
      _showErrors = true;
    });

    final hasError = _validateName() != null ||
        _validateLevel() != null ||
        _validateSubject() != null ||
        _validateTeacher() != null ||
        _validateStudents() != null;

    if (hasError) return;

    final course = MockCourse(
      name.text.trim(),
      teacher!,
      subject!,
      selectedStudents.length,
      _editingCourse?.percent ?? 0,
      active,
      description: desc.text.trim(),
      level: level.text.trim(),
      studentNames: selectedStudents.toList(),
    );

    if (_editingCourse == null) {
      mockCourses.add(course);
    } else {
      final index = mockCourses.indexOf(_editingCourse!);

      if (index != -1) {
        mockCourses[index] = course;
      } else {
        mockCourses.add(course);
      }
    }

    await showSuccessDialog(
      context,
      _editingCourse == null
          ? 'Course berhasil ditambahkan!'
          : 'Course berhasil diperbarui!',
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final edit = _editingCourse != null;

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

            FormCard(
              children: [
                // Nama course
                const FieldLabel('Nama Course', required: true),

                EduField(
                  controller: name,
                  hint: 'Masukkan nama course',
                  error: _showErrors && nameError != null,
                ),

                _errorText(nameError),

                // Mata pelajaran
                const FieldLabel('Mata Pelajaran', required: true),

                EduSelect(
                  hint: 'Pilih mata pelajaran',
                  value: subject,
                  items: const [
                    'Matematika',
                    'Bahasa Indonesia',
                    'KIK',
                    'Agama',
                    'Pendidikan Pancasila / Kewarganegaraan',
                    'Ilmu Pengetahuan Alam',
                    'Ilmu Pengetahuan Sosial',
                    'Bahasa Inggris',
                    'Agama',
                  ],
                  error: _showErrors && subjectError != null,
                  onChanged: (value) {
                    setState(() {
                      subject = value;
                    });
                  },
                ),

                _errorText(subjectError),

                // Deskripsi
                const FieldLabel('Deskripsi'),

                EduField(
                  controller: desc,
                  hint: 'Masukkan deskripsi course',
                  maxLines: 3,
                ),

                // Tingkat kelas
                const FieldLabel('Tingkat Kelas', required: true),

                EduSelect(
                  hint: 'Pilih tingkat kelas',
                  value: subject,
                  items: const [
                    'Kelas 7',
                    'Kelas 8',
                    'kelas 9',
                    'Kelas 10',
                    'Kelas 11',
                    'Kelas 12',
                  ],
                  error: _showErrors && subjectError != null,
                  onChanged: (value) {
                    setState(() {
                      subject = value;
                    });
                  },
                ),

                _errorText(levelError),

                // Guru pengajar
                const FieldLabel('Guru Pengajar', required: true),

                EduSelect(
                  hint: 'Pilih guru pengajar',
                  value: teacher,
                  items: availableTeachers
                      .map((user) => user.name)
                      .toList(),
                  error: _showErrors && teacherError != null,
                  onChanged: (value) {
                    setState(() {
                      teacher = value;
                    });
                  },
                ),

                _errorText(teacherError),

                // Pilih siswa
                const FieldLabel('Pilih Siswa', required: true),

                if (availableStudents.isEmpty)
                  const Text(
                    'Belum ada siswa aktif. Tambahkan siswa terlebih dahulu.',
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
                        color: _showErrors && studentsError != null
                            ? Ui.red
                            : Ui.line,
                        width: _showErrors && studentsError != null
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

                        const SizedBox(height: 6),

                        for (final user in availableStudents)
                          CheckboxListTile(
                            value: selectedStudents.contains(user.name),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            title: Text(
                              user.name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            subtitle: Text(
                              '${user.email} • ${user.info}',
                              style: const TextStyle(fontSize: 9),
                            ),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedStudents.add(user.name);
                                } else {
                                  selectedStudents.remove(user.name);
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

                // Status
                const FieldLabel('Status', required: true),

                StatusRadio(
                  active: active,
                  onChanged: (value) {
                    setState(() {
                      active = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                SolidBtn(
                  label: edit ? 'Simpan Perubahan' : 'Tambah Course',
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
}

