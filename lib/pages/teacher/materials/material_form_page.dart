import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../components/ui/kit.dart';
import '../../../components/ui/material_markdown.dart';
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
  final body = MaterialTextEditingController();
  final link = TextEditingController();
  final _bodyFocus = FocusNode();

  final _db = Supabase.instance.client;
  final _activityRepository = ActivityRepository();

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _imageMarkdown = RegExp(
    r'!\[([^\]\n]*)\]\((https?://[^)\s]+)(?:\s+"([^"\n]*)")?\)',
  );

  String? _courseId;
  String? _materialId;
  String?
  _argString; // String dari halaman sebelumnya: id course atau id materi

  PlatformFile? _pickedFile;
  String? _existingFileUrl;
  String? _existingFileName;

  bool _init = false;
  bool _loading = true;
  bool _saving = false;
  bool _imageUploading = false;
  bool _imagePresent = false;
  String? _loadError;

  bool get _isEdit => _materialId != null;

  @override
  void initState() {
    super.initState();
    body.addListener(_syncImageAvailability);
  }

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
    body.removeListener(_syncImageAvailability);
    for (final c in [title, desc, body, link]) {
      c.dispose();
    }
    _bodyFocus.dispose();
    super.dispose();
  }

  void _syncImageAvailability() {
    final containsImage = _imageMarkdown.hasMatch(body.text);
    if (containsImage == _imagePresent || !mounted) return;
    setState(() => _imagePresent = containsImage);
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
    final file = res.files.first;
    if (file.size > _maxFileBytes) {
      _snack('Ukuran file maksimal 100MB.');
      return;
    }
    setState(() => _pickedFile = file);
  }

  void _clearFile() => setState(() {
    _pickedFile = null;
    _existingFileUrl = null;
    _existingFileName = null;
  });

  Future<void> _openExternalLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _snack('Link tidak valid.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _snack('Link tidak dapat dibuka.');
    } catch (e) {
      debugPrint('[TeacherMaterialForm] Gagal membuka pratinjau: $e');
      _snack('Link tidak dapat dibuka.');
    }
  }

  Uri? get _videoUri {
    final value = link.text.trim();
    if (value.isEmpty) return null;
    final normalized = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  String? _youtubeVideoId(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'youtu.be') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) return videoId;
      if (uri.pathSegments.length > 1 &&
          const {'embed', 'shorts', 'live'}.contains(uri.pathSegments.first)) {
        return uri.pathSegments[1];
      }
    }
    return null;
  }

  Widget _videoPreview(Uri uri) {
    final videoId = _youtubeVideoId(uri);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Ui.line),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openExternalLink(uri.toString()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (videoId != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _videoPlaceholder(),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
              )
            else
              _videoPlaceholder(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.ondemand_video, size: 16, color: Ui.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      uri.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Ui.blue),
                    ),
                  ),
                  const Text(
                    'Buka video',
                    style: TextStyle(fontSize: 9, color: Ui.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoPlaceholder() => Container(
    height: 110,
    color: const Color(0xFFF1F5F9),
    alignment: Alignment.center,
    child: const Icon(Icons.play_circle_outline, size: 42, color: Ui.muted),
  );

  Widget _filePreview(String fileName) {
    final extension = fileName.split('.').last.toUpperCase();
    final fileSize = _pickedFile?.size;
    final savedUrl = _pickedFile == null ? _existingFileUrl : null;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: Ui.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Ui.greenDark, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  [
                    extension,
                    if (fileSize != null) _formatFileSize(fileSize),
                    if (savedUrl == null) 'Siap diunggah',
                  ].join(' • '),
                  style: const TextStyle(fontSize: 9, color: Ui.muted),
                ),
              ],
            ),
          ),
          if (savedUrl != null)
            TextButton(
              onPressed: () => _openExternalLink(savedUrl),
              child: const Text('Buka', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _imageFileName(Uri uri, String? title) {
    if (title != null && title.trim().isNotEmpty) return title.trim();
    final pathName = uri.pathSegments.isEmpty
        ? 'gambar'
        : Uri.decodeComponent(uri.pathSegments.last);
    return pathName.replaceFirst(RegExp(r'^\d+_'), '');
  }

  Widget _materialImagePreview(Uri uri, String? title, String? alt) {
    final fileName = _imageFileName(uri, title);
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'GAMBAR';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            uri.toString(),
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              width: double.infinity,
              height: 100,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: const Text(
                'Gambar tidak dapat dimuat',
                style: TextStyle(fontSize: 10, color: Ui.muted),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$fileName • $extension',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Ui.muted),
                ),
              ),
              IconButton(
                tooltip: 'Ganti gambar',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: _imageUploading ? null : () => _replaceImage(uri),
                icon: const Icon(Icons.edit_outlined, color: Ui.blue),
              ),
              IconButton(
                tooltip: 'Hapus gambar',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: () => _removeImage(uri),
                icon: const Icon(Icons.delete_outline, color: Ui.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageOnlyPreview() {
    final previews = _imageMarkdown.allMatches(body.text).map((match) {
      final uri = Uri.tryParse(match.group(2) ?? '');
      if (uri == null) return const SizedBox.shrink();
      return _materialImagePreview(uri, match.group(3), match.group(1));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Pratinjau Gambar'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Ui.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: previews,
          ),
        ),
      ],
    );
  }

  void _removeImage(Uri uri) {
    final match = _findImageMatch(uri);
    if (match == null) return;
    final updated = body.text.replaceRange(match.start, match.end, '');
    body.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: match.start),
    );
  }

  RegExpMatch? _findImageMatch(Uri uri) {
    for (final match in _imageMarkdown.allMatches(body.text)) {
      if (Uri.tryParse(match.group(2) ?? '') == uri) return match;
    }
    return null;
  }

  Future<({Uri uri, String name})?> _pickAndUploadImage() async {
    if (_saving || _imageUploading) return null;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final image = result.files.first;
      final extension = image.extension?.toLowerCase();
      const contentTypes = {
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'bmp': 'image/bmp',
      };
      final contentType = contentTypes[extension];
      if (contentType == null) {
        _snack('Format gambar harus PNG, JPG, GIF, WEBP, atau BMP.');
        return null;
      }
      if (image.size > _maxFileBytes) {
        _snack('Ukuran gambar maksimal 100MB.');
        return null;
      }
      final bytes = image.bytes;
      if (bytes == null) {
        _snack('Gambar tidak dapat dibaca. Coba pilih file lain.');
        return null;
      }
      final uid = _db.auth.currentUser?.id;
      if (uid == null || _courseId == null) {
        _snack('Sesi login atau course tidak ditemukan.');
        return null;
      }

      setState(() => _imageUploading = true);
      final safeName = image.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final path =
          '$uid/$_courseId/images/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await _db.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      if (!mounted) return null;
      return (
        uri: Uri.parse(_db.storage.from(_bucket).getPublicUrl(path)),
        name: image.name,
      );
    } catch (e) {
      debugPrint('[TeacherMaterialForm] Gagal mengimpor gambar: $e');
      _snack('Gagal mengimpor gambar: $e');
      return null;
    } finally {
      if (mounted) setState(() => _imageUploading = false);
    }
  }

  Future<void> _replaceImage(Uri currentImage) async {
    final uploaded = await _pickAndUploadImage();
    if (uploaded == null) return;
    final match = _findImageMatch(currentImage);
    if (match == null) {
      _snack('Gambar yang akan diganti tidak ditemukan.');
      return;
    }
    final safeTitle = uploaded.name.replaceAll('"', '_').replaceAll('\n', ' ');
    final replacement =
        '![${match.group(1) ?? ''}](${uploaded.uri} "$safeTitle")';
    body.value = TextEditingValue(
      text: body.text.replaceRange(match.start, match.end, replacement),
      selection: TextSelection.collapsed(
        offset: match.start + replacement.length,
      ),
    );
    _bodyFocus.requestFocus();
  }

  Future<Map<String, String>?> _uploadFile(String uid) async {
    final file = _pickedFile;
    if (file == null || file.bytes == null) return null;
    final extension = file.extension?.toLowerCase();
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => throw StateError('Format file materi tidak didukung.'),
    };
    final safeName = file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final path =
        '$uid/$_courseId/files/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _db.storage
        .from(_bucket)
        .uploadBinary(
          path,
          file.bytes!,
          fileOptions: FileOptions(contentType: contentType),
        );
    return {
      'url': _db.storage.from(_bucket).getPublicUrl(path),
      'name': file.name,
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
    return (
      start: s.start.clamp(0, len).toInt(),
      end: s.end.clamp(0, len).toInt(),
    );
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

  /// Convert list prefixes on the selected lines to the chosen list type.
  void _prefixLines({required bool numbered}) {
    final (:start, end: selectedEnd) = _sel;
    final text = body.text;
    final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
    final end =
        selectedEnd > start &&
            selectedEnd <= text.length &&
            text[selectedEnd - 1] == '\n'
        ? selectedEnd - 1
        : selectedEnd;
    final nextLineStart = text.indexOf('\n', end);
    final lineEnd = nextLineStart == -1 ? text.length : nextLineStart;
    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');
    final out = <String>[];
    final oldPrefixLengths = <int>[];
    final newPrefixLengths = <int>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final indentation = RegExp(r'^[ \t]*').firstMatch(line)!.group(0)!;
      final oldListPrefix = RegExp(
        r'^[ \t]*(?:[-*+]|\d+\.)[ \t]+',
      ).firstMatch(line)?.group(0);
      final content = oldListPrefix == null
          ? line.substring(indentation.length)
          : line.substring(oldListPrefix.length);
      final prefix = '$indentation${numbered ? '${i + 1}. ' : '- '}';
      out.add('$prefix$content');
      oldPrefixLengths.add(oldListPrefix?.length ?? indentation.length);
      newPrefixLengths.add(prefix.length);
    }
    final newBlock = out.join('\n');

    int adjustOffset(int offset) {
      var lineOffset = 0;
      var accumulatedDelta = 0;
      for (var i = 0; i < lines.length; i++) {
        final originalLineStart = lineStart + lineOffset;
        if (offset < originalLineStart) break;
        final oldPrefixEnd = originalLineStart + oldPrefixLengths[i];
        final newPrefixEnd =
            originalLineStart + accumulatedDelta + newPrefixLengths[i];
        if (offset <= oldPrefixEnd) return newPrefixEnd;
        accumulatedDelta += newPrefixLengths[i] - oldPrefixLengths[i];
        lineOffset += lines[i].length + 1;
      }
      return offset + accumulatedDelta;
    }

    final adjustedStart = adjustOffset(start);
    final adjustedEnd = adjustOffset(selectedEnd);
    body.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineEnd, newBlock),
      selection: TextSelection(
        baseOffset: adjustedStart,
        extentOffset: adjustedEnd,
      ),
    );
    _bodyFocus.requestFocus();
  }

  Future<String?> _askUrl(String label) async {
    final c = TextEditingController();
    final result = await showDialog<String>(
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
    c.dispose();
    return result;
  }

  Future<void> _insertLink() async {
    final (:start, :end) = _sel;
    final selected = body.text.substring(start, end);
    final url = await _askUrl('Masukkan link');
    if (url == null || url.trim().isEmpty) return;
    final value = url.trim();
    final normalizedUrl = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      _snack('Masukkan alamat link yang valid.');
      return;
    }
    final label = selected.isEmpty ? normalizedUrl : selected;
    _wrapWith(
      '[$label]($normalizedUrl)',
      start,
      end,
      visibleStart: 1,
      visibleLength: label.length,
    );
  }

  Future<void> _insertImage() async {
    if (_saving || _imageUploading) return;
    final (:start, :end) = _sel;
    final selected = body.text.substring(start, end);
    final uploaded = await _pickAndUploadImage();
    if (uploaded == null) return;
    final safeTitle = uploaded.name.replaceAll('"', '_').replaceAll('\n', ' ');
    _wrapWith(
      '![$selected](${uploaded.uri} "$safeTitle")',
      start,
      end,
      visibleStart: 2,
      visibleLength: selected.length,
    );
  }

  void _wrapWith(
    String replacement,
    int start,
    int end, {
    required int visibleStart,
    required int visibleLength,
  }) {
    final text = body.text;
    final s = start.clamp(0, text.length).toInt();
    final e = end.clamp(0, text.length).toInt();
    body.value = TextEditingValue(
      text: text.replaceRange(s, e, replacement),
      selection: TextSelection(
        baseOffset: s + visibleStart,
        extentOffset: s + visibleStart + visibleLength,
      ),
    );
    _bodyFocus.requestFocus();
  }

  Widget _tool(Widget child, String tip, VoidCallback? onTap) => Tooltip(
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
                      Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: (_imageUploading || _imagePresent)
                            ? Ui.muted
                            : Ui.text,
                      ),
                      _imagePresent
                          ? 'Hapus atau ganti gambar melalui pratinjau'
                          : 'Import gambar',
                      (_imageUploading || _imagePresent) ? null : _insertImage,
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
        AnimatedBuilder(
          animation: body,
          builder: (context, _) {
            if (!_imagePresent) return const SizedBox.shrink();
            return _imageOnlyPreview();
          },
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
        if (fileName != null) _filePreview(fileName),
        const FieldLabel('Link Video (Opsional)'),
        EduField(
          hint: 'Masukkan link video youtube dll',
          controller: link,
          prefix: const Icon(Icons.link, size: 15),
        ),
        AnimatedBuilder(
          animation: link,
          builder: (context, _) {
            final uri = _videoUri;
            if (uri == null) return const SizedBox.shrink();
            return _videoPreview(uri);
          },
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
