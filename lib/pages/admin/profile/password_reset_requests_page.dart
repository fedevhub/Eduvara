import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/ui/kit.dart';

class PasswordResetRequestsPage extends StatefulWidget {
  const PasswordResetRequestsPage({super.key});

  @override
  State<PasswordResetRequestsPage> createState() =>
      _PasswordResetRequestsPageState();
}

class _PasswordResetRequestsPageState extends State<PasswordResetRequestsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'password-reset',
        body: {'action': 'list'},
      );
      final data = response.data;
      if (response.status != 200 || data is! Map || data['requests'] is! List) {
        throw StateError('Daftar permintaan tidak dapat dimuat.');
      }
      if (!mounted) return;
      setState(() {
        _requests = List<Map<String, dynamic>>.from(
          (data['requests'] as List).map(
            (row) => Map<String, dynamic>.from(row as Map),
          ),
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat permintaan reset password.\n$error';
        _loading = false;
      });
    }
  }

  Future<void> _review(Map<String, dynamic> request, String decision) async {
    final id = request['id'].toString();
    final approved = decision == 'approve';
    final confirmed = await showConfirmWarning(
      context,
      title: approved ? 'Setujui Reset Password?' : 'Tolak Permintaan?',
      message: approved
          ? 'Password baru untuk ${request['username']} akan langsung diaktifkan.'
          : 'Permintaan reset password ${request['username']} akan ditolak.',
      primary: approved ? 'Setujui' : 'Tolak',
    );
    if (!confirmed || !mounted) return;

    setState(() => _processing.add(id));
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'password-reset',
        body: {'action': 'review', 'id': id, 'decision': decision},
      );
      if (response.status != 200) {
        throw StateError('Permintaan tidak dapat diproses.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Password berhasil direset.'
                : 'Permintaan reset password ditolak.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses permintaan: $error')),
      );
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'admin', current: 1),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackLink(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Permintaan Reset Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Ui.text,
                ),
              ),
            ),
            if (!_loading && _requests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Ui.blueTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_requests.length} menunggu',
                  style: const TextStyle(
                    color: Ui.blueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: Ui.blue))
        else if (_error != null)
          EduCard(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Ui.red),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Ui.text),
                ),
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              ],
            ),
          )
        else if (_requests.isEmpty)
          const EduCard(
            child: Column(
              children: [
                Icon(Icons.mark_email_read_outlined, color: Ui.muted, size: 32),
                SizedBox(height: 8),
                Text(
                  'Tidak ada permintaan yang menunggu.',
                  style: TextStyle(color: Ui.muted),
                ),
              ],
            ),
          )
        else
          ..._requests.map((request) {
            final id = request['id'].toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EduCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DarkAvatar(
                          name: request['full_name']?.toString(),
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            request['full_name']?.toString() ?? '-',
                            style: const TextStyle(
                              color: Ui.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Pill('Menunggu', kind: PillKind.locked),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.person_outline,
                      'Username',
                      request['username']?.toString() ?? '-',
                    ),
                    _infoRow(
                      Icons.badge_outlined,
                      'Role',
                      request['role']?.toString() ?? '-',
                    ),
                    if (request['class_name'] != null)
                      _infoRow(
                        Icons.class_outlined,
                        'Kelas',
                        request['class_name'].toString(),
                      ),
                    _infoRow(
                      Icons.schedule_outlined,
                      'Diajukan',
                      _date(request['created_at']),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _processing.contains(id)
                                ? null
                                : () => _review(request, 'reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Ui.red,
                              side: const BorderSide(color: Ui.redSoft),
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _processing.contains(id)
                                ? null
                                : () => _review(request, 'approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Ui.blue,
                              foregroundColor: Colors.white,
                            ),
                            icon: _processing.contains(id)
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check, size: 18),
                            label: Text(
                              _processing.contains(id)
                                  ? 'Memproses...'
                                  : 'Setujui',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 15, color: Ui.muted),
        const SizedBox(width: 7),
        Text('$label: ', style: const TextStyle(color: Ui.muted, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Ui.text, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
