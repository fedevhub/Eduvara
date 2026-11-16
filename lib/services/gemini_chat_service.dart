import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiChatService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> sendMessage({
    required String message,
    required List<Map<String, String>> history,
    String? attachmentBase64,
    String? attachmentMimeType,
  }) async {
    final response = await _client.functions.invoke(
      'gemini-chat',
      body: {
        'message': message,
        'history': history,
        if (attachmentBase64 != null) 'attachment_base64': attachmentBase64,
        if (attachmentMimeType != null)
          'attachment_mime_type': attachmentMimeType,
      },
    );

    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map) {
      throw Exception('Gemini belum dapat memproses pesan. Coba lagi.');
    }

    final reply = data['reply']?.toString().trim() ?? '';

    if (reply.isEmpty) {
      throw Exception(
        'Gemini memberikan jawaban kosong. Coba pertanyaan lain.',
      );
    }

    return reply;
  }
}
