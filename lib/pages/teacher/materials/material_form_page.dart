import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';

/// Tambah / Edit materi (guru). Argumen String = mode edit.
class TeacherMaterialFormPage extends StatefulWidget {
  const TeacherMaterialFormPage({super.key});
  @override
  State<TeacherMaterialFormPage> createState() =>
      _TeacherMaterialFormPageState();
}

class _TeacherMaterialFormPageState extends State<TeacherMaterialFormPage> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final body = TextEditingController();
  final link = TextEditingController();
  String? course;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) title.text = arg;
  }

  @override
  void dispose() {
    for (final c in [title, desc, body, link]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _tool(Widget w) =>
      Padding(padding: const EdgeInsets.only(right: 12), child: w);

  @override
  Widget build(BuildContext context) {
    final edit = ModalRoute.of(context)?.settings.arguments is String;
    return EduScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackLink(),
          const SizedBox(height: 4),
          Text(
            edit ? 'Edit Materi' : 'Tambah Materi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          FormCard(
            children: [
              const FieldLabel('Course', required: true),
              EduSelect(
                value: course,
                items: const [
                  'Matematika Kelas 10',
                  'Matematika Kelas 11',
                  'Matematika Kelas 12',
                ],
                onChanged: (v) => setState(() => course = v),
              ),
              const FieldLabel('Judul Materi', required: true),
              EduField(controller: title),
              const FieldLabel('Deskripsi Materi', required: true),
              EduField(
                hint: 'Deskripsi Materi',
                maxLines: 3,
                controller: desc,
              ),
              const FieldLabel('Isi Materi', required: true),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Ui.line),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        children: [
                          _tool(const Text('B', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
                          _tool(const Text('I', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic))),
                          _tool(const Text('U', style: TextStyle(fontSize: 11, decoration: TextDecoration.underline))),
                          _tool(const Icon(Icons.format_list_bulleted, size: 14)),
                          _tool(const Icon(Icons.format_list_numbered, size: 14)),
                          _tool(const Icon(Icons.link, size: 14)),
                          _tool(const Icon(Icons.image_outlined, size: 14)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: body,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Tulis isi materi disini',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB6BFCC),
                        ),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              const FieldLabel('File Materi'),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Ui.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Ui.greenSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 15,
                        color: Ui.greenDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'Pilih file',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Ui.blue,
                              ),
                              children: [
                                TextSpan(
                                  text: ' atau klik untuk upload',
                                  style: TextStyle(color: Ui.text),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Format: PDF, DOC, DOCX | Maks: 100MB',
                            style: TextStyle(fontSize: 7.5, color: Ui.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const FieldLabel('Link Video (Opsional)'),
              EduField(
                hint: 'Masukkan link video youtube disini',
                controller: link,
                prefix: const Icon(Icons.link, size: 15),
              ),
              const SizedBox(height: 16),
              SolidBtn(
                label: edit ? 'Simpan Perubahan' : 'Tambah Materi',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
