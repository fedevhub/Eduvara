import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> record({
    required String action,
    required String entity,
    required String entityName,
  }) async {
    await _db.rpc(
      'record_user_activity',
      params: {
        'p_action': action,
        'p_entity': entity,
        'p_entity_name': entityName,
      },
    );
  }
}
