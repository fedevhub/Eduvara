import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../../components/ui/kit.dart';
import '../../services/gemini_chat_service.dart';

const _promptPool = [
  'Jelaskan konsep OOP dengan contoh sederhana',
  'Apa perbedaan LAN, MAN, dan WAN?',
  'Bantu aku memahami rangkaian elektronika dasar',
  'Jelaskan cara kerja database relasional',
  'Buatkan contoh algoritma percabangan sederhana',
  'Apa fungsi jaringan komputer di sekolah?',
];

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _db = Supabase.instance.client;
  final _service = GeminiChatService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMessage> _messages = [];

  String? _conversationId;
  bool _loadingHistory = false;
  bool _sending = false;
  String? _error;
  PlatformFile? _pendingImage;
  String? _wordDocumentText;
  late final List<String> _suggestions;

  @override
  void initState() {
    super.initState();
    // Opening the assistant always starts a fresh conversation. Older chats
    // remain available from the history page.
    _suggestions = List.of(_promptPool)..shuffle(math.Random());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadConversation(String conversationId) async {
    try {
      _conversationId = conversationId;
      final messages = await _db
          .from('ai_messages')
          .select('id, role, content')
          .eq('conversation_id', _conversationId!)
          .order('created_at');

      _messages
        ..clear()
        ..addAll(
          messages.map(
            (row) => _ChatMessage(
              id: row['id'].toString(),
              role: row['role'].toString(),
              content: row['content'].toString(),
            ),
          ),
        );
    } catch (e) {
      _error =
          'Riwayat chat belum dapat dimuat. Kamu tetap bisa memulai chat baru.';

      debugPrint('[AiChatPage] load history: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }

      _scrollToBottom();
    }
  }

  Future<String> _ensureConversation(String initialMessage) async {
    if (_conversationId != null) return _conversationId!;

    final user = _db.auth.currentUser;

    if (user == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final row = await _db
        .from('ai_conversations')
        .insert({
          'user_id': user.id,
          'title': initialMessage.length > 56
              ? '${initialMessage.substring(0, 56)}…'
              : initialMessage,
        })
        .select('id')
        .single();

    _conversationId = row['id'].toString();

    return _conversationId!;
  }

  Future<void> _send() async {
    final text = _input.text.trim();

    if ((text.isEmpty && _pendingImage == null) || _sending) return;

    final image = _pendingImage;
    final wordText = _wordDocumentText;
    final attachmentMimeType = _mimeTypeFor(image);
    final isImageAttachment = attachmentMimeType?.startsWith('image/') ?? false;
    final userText = text.isEmpty
        ? 'Tolong jelaskan lampiran ini untuk keperluan belajar.'
        : text;
    final storedUserText = image == null
        ? userText
        : '$userText\n\n📎 ${image.name}';
    final requestText = wordText == null
        ? userText
        : '$userText\n\nIsi dokumen Word:\n$wordText';

    setState(() {
      _sending = true;
      _error = null;

      _messages.add(
        _ChatMessage(
          role: 'user',
          content: storedUserText,
          imageBytes: isImageAttachment ? image?.bytes : null,
        ),
      );
    });

    _input.clear();
    _pendingImage = null;
    _wordDocumentText = null;
    _scrollToBottom();

    try {
      final conversationId = await _ensureConversation(userText);

      final savedUser = await _db
          .from('ai_messages')
          .insert({
            'conversation_id': conversationId,
            'user_id': _db.auth.currentUser!.id,
            'role': 'user',
            'content': storedUserText,
          })
          .select('id')
          .single();
      _messages[_messages.length - 1] = _messages.last.copyWith(
        id: savedUser['id'].toString(),
      );

      final history = _messages
          .take(_messages.length - 1)
          .toList()
          .reversed
          .take(12)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final reply = await _service.sendMessage(
        message: requestText,
        history: history,
        attachmentBase64: image?.bytes == null || wordText != null
            ? null
            : base64Encode(image!.bytes!),
        attachmentMimeType: attachmentMimeType,
      );

      final savedReply = await _db
          .from('ai_messages')
          .insert({
            'conversation_id': conversationId,
            'user_id': _db.auth.currentUser!.id,
            'role': 'model',
            'content': reply,
          })
          .select('id')
          .single();

      await _db
          .from('ai_conversations')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', conversationId);

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              id: savedReply['id'].toString(),
              role: 'model',
              content: reply,
            ),
          );
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[AiChatPage] send: $e');

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: 'model',
              content:
                  'Maaf, pesan belum berhasil diproses. Periksa koneksi atau konfigurasi Gemini, lalu coba lagi.',
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }

      _scrollToBottom();
    }
  }

  Future<void> _newChat() async {
    if (_sending) return;

    setState(() {
      _conversationId = null;
      _messages.clear();
      _error = null;
      _pendingImage = null;
      _wordDocumentText = null;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.bytes == null || file.size > 4 * 1024 * 1024) {
      if (mounted) _showSnack('Pilih gambar maksimal 4 MB.');
      return;
    }
    setState(() => _pendingImage = file);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    await _acceptAttachment(result?.files.single);
  }

  Future<void> _pickWord() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx', 'doc'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.extension?.toLowerCase() == 'doc') {
      _showSnack(
        'File .doc lama belum didukung. Simpan sebagai .docx atau PDF terlebih dahulu.',
      );
      return;
    }
    try {
      if (file.bytes == null || file.size > 4 * 1024 * 1024) {
        _showSnack('Pilih file Word maksimal 4 MB.');
        return;
      }
      final archive = ZipDecoder().decodeBytes(file.bytes!);
      final document = archive.findFile('word/document.xml');
      if (document == null) throw const FormatException();
      final xml = utf8.decode(document.content as List<int>);
      final text = xml
          .replaceAll(RegExp(r'<w:tab[^>]*/>'), '\t')
          .replaceAll(RegExp(r'</w:p>'), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();
      if (text.isEmpty) throw const FormatException();
      setState(() {
        _pendingImage = file;
        _wordDocumentText = text.length > 24000
            ? text.substring(0, 24000)
            : text;
      });
    } catch (_) {
      _showSnack('Dokumen Word tidak dapat dibaca. Coba ekspor menjadi PDF.');
    }
  }

  Future<void> _acceptAttachment(PlatformFile? file) async {
    if (file == null) return;
    if (file.bytes == null || file.size > 4 * 1024 * 1024) {
      _showSnack('Pilih file maksimal 4 MB.');
      return;
    }
    setState(() {
      _pendingImage = file;
      _wordDocumentText = null;
    });
  }

  String? _mimeTypeFor(PlatformFile? file) {
    if (file == null || _wordDocumentText != null) return null;
    return switch (file.extension?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
  }

  Future<void> _showAttachmentMenu() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Gambar'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Dokumen PDF'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickPdf();
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Dokumen Word (.docx)'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickWord();
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _deleteMessage(int index) async {
    if (_sending) return;
    final message = _messages[index];
    if (message.id != null) {
      await _db.from('ai_messages').delete().eq('id', message.id!);
    }
    if (mounted) setState(() => _messages.removeAt(index));
  }

  Future<void> _editQuestion(int index) async {
    if (_sending || _messages[index].role != 'user') return;
    final controller = TextEditingController(text: _messages[index].content);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit pertanyaan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kirim ulang'),
          ),
        ],
      ),
    );
    if (updated == null || updated.isEmpty) return;

    final discarded = _messages.sublist(index);
    final ids = discarded.map((m) => m.id).whereType<String>().toList();
    if (ids.isNotEmpty) {
      await _db.from('ai_messages').delete().inFilter('id', ids);
    }
    setState(() {
      _messages.removeRange(index, _messages.length);
      _input.text = updated;
    });
    await _send();
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _AiHistoryPage()));
    if (selected == null || !mounted) return;
    setState(() {
      _loadingHistory = true;
      _error = null;
      _pendingImage = null;
    });
    await _loadConversation(selected);
  }

  void _showSnack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = (_db.auth.currentUser?.userMetadata?['role'] ?? 'pengguna')
        .toString();

    return Scaffold(
      backgroundColor: Ui.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Ui.blueTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Ui.blue),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eduvara AI',
                  style: TextStyle(
                    color: Ui.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'AI Learning Assistant',
                  style: TextStyle(color: Ui.muted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat chat',
            onPressed: _sending ? null : _openHistory,
            icon: const Icon(Icons.history_rounded, color: Ui.navy),
          ),
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: _newChat,
            icon: const Icon(Icons.add_comment_outlined, color: Ui.navy),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Ui.blueTint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 15, color: Ui.blue),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Asisten belajar untuk $role. Periksa kembali informasi penting.',
                    style: const TextStyle(fontSize: 10, color: Ui.navy),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _error!,
                style: const TextStyle(color: Ui.orangeDark, fontSize: 11),
              ),
            ),

          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _welcome()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _TypingBubble();
                      }

                      return _MessageBubble(
                        message: _messages[index],
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _messages[index].content),
                          );
                          if (context.mounted) _showSnack('Pesan disalin.');
                        },
                        onEdit: _messages[index].role == 'user'
                            ? () => _editQuestion(index)
                            : null,
                        onDelete: () => _deleteMessage(index),
                      );
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Ui.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Tambah lampiran',
                    onPressed: _sending ? null : _showAttachmentMenu,
                    icon: const Icon(Icons.attach_file_rounded, color: Ui.blue),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_pendingImage != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Ui.blueTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pendingImage!.extension?.toLowerCase() ==
                                          'pdf'
                                      ? Icons.picture_as_pdf_outlined
                                      : _wordDocumentText != null
                                      ? Icons.description_outlined
                                      : Icons.image,
                                  size: 16,
                                  color: Ui.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _pendingImage!.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () =>
                                      setState(() => _pendingImage = null),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Tanyakan sesuatu atau upload gambar...',
                            hintStyle: const TextStyle(fontSize: 12),
                            filled: true,
                            fillColor: Ui.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: Ui.blue,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Ui.blueTint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: Ui.blue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Halo! Ada yang bisa dipelajari?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Ui.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tanyakan materi, minta penjelasan, atau diskusikan soal yang sedang kamu pelajari.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Ui.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          for (final prompt in _suggestions.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  _input.text = prompt;
                  _send();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Ui.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Ui.blue,
                        size: 17,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(fontSize: 11, color: Ui.text),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Ui.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ChatMessage {
  final String? id;
  final String role;
  final String content;
  final Uint8List? imageBytes;

  const _ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.imageBytes,
  });

  _ChatMessage copyWith({String? id}) => _ChatMessage(
    id: id ?? this.id,
    role: role,
    content: content,
    imageBytes: imageBytes,
  );
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.min(constraints.maxWidth * .9, 720.0);
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Ui.blue : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isUser ? null : Border.all(color: Ui.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        message.imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Ui.text,
                              fontSize: 12,
                              height: 1.5,
                            ),
                            h1: const TextStyle(
                              color: Ui.text,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: const TextStyle(
                              color: Ui.text,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: const TextStyle(
                              color: Ui.text,
                              fontSize: 12,
                            ),
                          ),
                        ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _action(Icons.copy_outlined, 'Salin', onCopy, isUser),
                      if (onEdit != null)
                        _action(Icons.edit_outlined, 'Edit', onEdit!, isUser),
                      _action(Icons.delete_outline, 'Hapus', onDelete, isUser),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _action(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
    bool isUser,
  ) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 16,
    color: isUser ? Colors.white70 : Ui.muted,
    onPressed: onTap,
    icon: Icon(icon),
  );
}

class _AiHistoryPage extends StatefulWidget {
  const _AiHistoryPage();

  @override
  State<_AiHistoryPage> createState() => _AiHistoryPageState();
}

class _AiHistoryPageState extends State<_AiHistoryPage> {
  final _db = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _history = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];
    final rows = await _db
        .from('ai_conversations')
        .select('id, title, updated_at')
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    appBar: AppBar(
      title: const Text('Riwayat chat'),
      backgroundColor: Colors.white,
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _history,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada riwayat percakapan.',
              style: TextStyle(color: Ui.muted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Ui.blueTint,
                  child: Icon(Icons.chat_bubble_outline, color: Ui.blue),
                ),
                title: Text(item['title']?.toString() ?? 'Percakapan baru'),
                subtitle: Text(
                  item['updated_at']
                          ?.toString()
                          .replaceFirst('T', ' ')
                          .split('.')
                          .first ??
                      '',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, item['id'].toString()),
              ),
            );
          },
        );
      },
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Ui.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
