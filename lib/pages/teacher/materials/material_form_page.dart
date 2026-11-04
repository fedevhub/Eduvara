import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../repositories/activity_repository.dart';

/// Tambah / Edit materi (guru).
/// Course tidak dipilih di form ini, tapi dibawa dari halaman sebelumnya.
/// Argumen yang dikenali:
///   - String id course   → tambah materi untuk course tersebut
///   - String id materi   → edit materi
///   - Map {'id': id materi (opsional), 'course_id': id course}
///
/// Isi materi disimpan sebagai teks Markdown:
///   **tebal**  *miring*  <u>garis bawah</u>  - bullet  1. nomor  [teks](url)  ![](url)
class TeacherMaterialFormPage extends StatefulWidget {
  const TeacherMaterialFormPage({super.key});
  @override
  State<TeacherMaterialFormPage> createState() =>
      _TeacherMaterialFormPageState();
}

class _TeacherMaterialFormPageState extends State<TeacherMaterialFormPage> {
  static const _bucket = 'materials';
  static const _maxFileBytes = 100 * 1024 * 1024;

  final title = TextEditingController();
  final desc = TextEditingController();
  final body = TextEditingController();
  final link = TextEditingController();
  final _bodyFocus = FocusNode();

  final _db = Supabase.instance.client;
  final _activityRepository = ActivityRepository();

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String? _courseId;
  String? _materialId;
  String?
  _argString; // String dari halaman sebelumnya: id course atau id materi

  // File materi
  PlatformFile? _pickedFile;
  String? _existingFileUrl;
  String? _existingFileName;

  bool _init = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  bool get _isEdit => _materialId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    debugPrint(
      '[TeacherMaterialForm] argumen diterima: $arg (${arg.runtimeType})',
    );
    if (arg is String) {
      _argString = arg.trim();
    } else if (arg is Map) {
      _materialId = arg['id']?.toString();
      _courseId = arg['course_id']?.toString();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [title, desc, body, link]) {
      c.dispose();
    }
    _bodyFocus.dispose();
    super.dispose();
  }

  // ───────────────────────── DATA ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) throw 'Sesi login tidak ditemukan.';

      // Argumen String: id course (tambah materi) atau id materi (edit)
      final a = _argString;
      if (a != null && a.isNotEmpty) {
        if (_uuid.hasMatch(a)) {
          final c = await _db
              .from('courses')
              .select('id')
              .eq('id', a)
              .maybeSingle();
          if (c != null) {
            _courseId = a;
          } else {
            _materialId = a;
          }
        } else {
          _materialId = a;
        }
        _argString = null;
      }

      if (_materialId != null) {
        final m = await _db
            .from('materials')
            .select()
            .eq('id', _materialId!)
            .single();
        title.text = (m['title'] ?? '').toString();
        desc.text = (m['description'] ?? '').toString();
        body.text = (m['content'] ?? '').toString();
        link.text = (m['video_url'] ?? '').toString();
        _courseId = m['course_id']?.toString() ?? _courseId;
        _existingFileUrl = m['file_url']?.toString();
        _existingFileName = m['file_name']?.toString();
      }
    } catch (e) {
      debugPrint('[TeacherMaterialForm] Gagal memuat data: $e');
      _loadError = 'Gagal memuat data: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    if (f.size > _maxFileBytes) {
      _snack('Ukuran file maksimal 100MB.');
      return;
    }
    setState(() => _pickedFile = f);
  }

  void _clearFile() => setState(() {
    _pickedFile = null;
    _existingFileUrl = null;
    _existingFileName = null;
  });

  Future<Map<String, String>?> _uploadFile(String uid) async {
    final f = _pickedFile;
    if (f == null || f.bytes == null) return null;
    final safeName = f.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _db.storage.from(_bucket).uploadBinary(path, f.bytes!);
    return {
      'url': _db.storage.from(_bucket).getPublicUrl(path),
      'name': f.name,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final materialName = title.text.trim();

    if (_courseId == null) {
      return _snack(
        'Course tidak diketahui. Buka halaman ini dari detail course.',
      );
    }
    if (materialName.isEmpty) return _snack('Judul materi wajib diisi.');
    if (desc.text.trim().isEmpty) {
      return _snack('Deskripsi materi wajib diisi.');
    }
    if (body.text.trim().isEmpty) return _snack('Isi materi wajib diisi.');

    final uid = _db.auth.currentUser?.id;
    if (uid == null) return _snack('Sesi login tidak ditemukan.');

    setState(() => _saving = true);
    try {
      final uploaded = await _uploadFile(uid);

      final data = <String, dynamic>{
        'course_id': _courseId,
        'title': materialName,
        'description': desc.text.trim(),
        'content': body.text.trim(),
        'video_url': link.text.trim().isEmpty ? null : link.text.trim(),
        // file baru > file lama > dihapus
        'file_url': uploaded?['url'] ?? _existingFileUrl,
        'file_name': uploaded?['name'] ?? _existingFileName,
      };

      if (_isEdit) {
        await _db.from('materials').update(data).eq('id', _materialId!);
      } else {
        await _db.from('materials').insert({...data, 'created_by': uid});
      }
    } catch (e) {
      debugPrint('[TeacherMaterialForm] Gagal menyimpan materi: $e');
      if (mounted) {
        _snack('Gagal menyimpan materi: $e');
        setState(() => _saving = false);
      }
      return;
    }

    // Kegagalan pencatatan aktivitas tidak membatalkan penyimpanan materi.
    try {
      await _activityRepository.record(
        action: _isEdit ? 'update' : 'insert',
        entity: 'material',
        entityName: materialName,
      );
    } catch (e) {
      debugPrint('[TeacherMaterialForm] Gagal mencatat aktivitas: $e');
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────── TOOLBAR EDITOR (Markdown) ───────────────

  ({int start, int end}) get _sel {
    final s = body.selection;
    final len = body.text.length;
    if (!s.isValid) return (start: len, end: len);
    return (start: s.start.clamp(0, len), end: s.end.clamp(0, len));
  }

  /// Bungkus teks terpilih, mis. **teks**.
  void _wrap(String left, String right, {String placeholder = 'teks'}) {
    final (:start, :end) = _sel;
    final text = body.text;
    final selected = text.substring(start, end);
    final inner = selected.isEmpty ? placeholder : selected;
    body.value = TextEditingValue(
      text: text.replaceRange(start, end, '$left$inner$right'),
      selection: TextSelection(
        baseOffset: start + left.length,
        extentOffset: start + left.length + inner.length,
      ),
    );
    _bodyFocus.requestFocus();
  }

  /// Awali setiap baris terpilih dengan "- " atau "1. ".
  void _prefixLines({required bool numbered}) {
    final (:start, :end) = _sel;
    final text = body.text;
    final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
    final block = text.substring(lineStart, end);
    final lines = block.split('\n');
    final out = <String>[];
    for (var i = 0; i < lines.length; i++) {
      out.add('${numbered ? '${i + 1}. ' : '- '}${lines[i]}');
    }
    final newBlock = out.join('\n');
    body.value = TextEditingValue(
      text: text.replaceRange(lineStart, end, newBlock),
      selection: TextSelection.collapsed(offset: lineStart + newBlock.length),
    );
    _bodyFocus.requestFocus();
  }

  Future<String?> _askUrl(String label) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label, style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _insertLink() async {
    final (:start, :end) = _sel;
    final selected = body.text.substring(start, end);
    final url = await _askUrl('Masukkan link');
    if (url == null || url.isEmpty) return;
    _wrapWith(
      '[${selected.isEmpty ? 'teks link' : selected}]($url)',
      start,
      end,
    );
  }

  Future<void> _insertImage() async {
    final (:start, :end) = _sel;
    final url = await _askUrl('Masukkan link gambar');
    if (url == null || url.isEmpty) return;
    _wrapWith('![gambar]($url)', start, end);
  }

  void _wrapWith(String replacement, int start, int end) {
    final text = body.text;
    final s = start.clamp(0, text.length);
    final e = end.clamp(0, text.length);
    body.value = TextEditingValue(
      text: text.replaceRange(s, e, replacement),
      selection: TextSelection.collapsed(offset: s + replacement.length),
    );
    _bodyFocus.requestFocus();
  }

  Widget _tool(Widget child, String tip, VoidCallback onTap) => Tooltip(
    message: tip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
        child: child,
      ),
    ),
  );

  // ───────────────────────── UI ─────────────────────────

  String? get _currentFileName => _pickedFile?.name ?? _existingFileName;

  @override
  Widget build(BuildContext context) {
    return EduScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackLink(),
          const SizedBox(height: 4),
          Text(
            _isEdit ? 'Edit Materi' : 'Tambah Materi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Center(
              child: Column(
                children: [
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
                ],
              ),
            )
          else
            _form(),
        ],
      ),
    );
  }

  Widget _form() {
    final fileName = _currentFileName;
    return FormCard(
      children: [
        const FieldLabel('Judul Materi', required: true),
        EduField(controller: title),
        const FieldLabel('Deskripsi Materi', required: true),
        EduField(hint: 'Deskripsi Materi', maxLines: 3, controller: desc),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: Row(
                  children: [
                    _tool(
                      const Text(
                        'B',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      'Tebal',
                      () => _wrap('**', '**'),
                    ),
                    _tool(
                      const Text(
                        'I',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      'Miring',
                      () => _wrap('*', '*'),
                    ),
                    _tool(
                      const Text(
                        'U',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      'Garis bawah',
                      () => _wrap('<u>', '</u>'),
                    ),
                    _tool(
                      const Icon(Icons.format_list_bulleted, size: 14),
                      'Daftar poin',
                      () => _prefixLines(numbered: false),
                    ),
                    _tool(
                      const Icon(Icons.format_list_numbered, size: 14),
                      'Daftar nomor',
                      () => _prefixLines(numbered: true),
                    ),
                    _tool(
                      const Icon(Icons.link, size: 14),
                      'Sisipkan link',
                      _insertLink,
                    ),
                    _tool(
                      const Icon(Icons.image_outlined, size: 14),
                      'Sisipkan gambar (link)',
                      _insertImage,
                    ),
                  ],
                ),
              ),
              TextField(
                controller: body,
                focusNode: _bodyFocus,
                maxLines: 5,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Tulis isi materi disini',
                  hintStyle: TextStyle(fontSize: 11, color: Color(0xFFB6BFCC)),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        const FieldLabel('File Materi'),
        InkWell(
          onTap: _saving ? null : _pickFile,
          borderRadius: BorderRadius.circular(8),
          child: Container(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileName == null)
                        const Text.rich(
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
                        )
                      else
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Ui.text,
                          ),
                        ),
                      const Text(
                        'Format: PDF, DOC, DOCX | Maks: 100MB',
                        style: TextStyle(fontSize: 7.5, color: Ui.muted),
                      ),
                    ],
                  ),
                ),
                if (fileName != null)
                  InkWell(
                    onTap: _saving ? null : _clearFile,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Ui.muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const FieldLabel('Link Video (Opsional)'),
        EduField(
          hint: 'Masukkan link video youtube dll',
          controller: link,
          prefix: const Icon(Icons.link, size: 15),
        ),
        const SizedBox(height: 16),
        SolidBtn(
          label: _isEdit ? 'Simpan Perubahan' : 'Tambah Materi',
          onTap: _saving ? null : _save,
        ),
      ],
    );
  }
}
