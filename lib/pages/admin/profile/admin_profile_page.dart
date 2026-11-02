import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  static const _namaSekolah = 'SMK Negeri 8 Malang';
  static const _bulanMulaiTahunAjaran = 7;

  final _db = Supabase.instance.client;

  late String _tahunAjaran;
  late Stream<int> _classCountStream;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  static String _hitungTahunAjaran(DateTime now) {
    final mulai = now.month >= _bulanMulaiTahunAjaran ? now.year : now.year - 1;
    return '$mulai/${mulai + 1}';
  }

  void _bind() {
    _tahunAjaran = _hitungTahunAjaran(DateTime.now());
    _classCountStream = _db
        .from('classes')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.length);
  }

  Future<void> _logout() async {
    final ok = await showConfirmWarning(
      context,
      title: 'Keluar dari panel admin?',
      message: 'Kamu akan keluar dari Eduvara.',
      primary: 'Ya, Keluar',
    );
    if (!ok) return;

    try {
      await _db.auth.signOut();
    } catch (_) {
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) => EduScaffold(
    scroll: false,
    bottom: const EduBottomNav(role: 'admin', current: 3),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'Setting',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'INFORMASI SEKOLAH',
          style: TextStyle(fontSize: 8, color: Ui.muted),
        ),
        const SizedBox(height: 6),
        EduCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              const _Row('Nama Sekolah', _namaSekolah),
              _Row('Tahun Ajaran', _tahunAjaran),
              StreamBuilder<int>(
                stream: _classCountStream,
                builder: (context, snap) {
                  final text = snap.hasError
                      ? 'Gagal memuat'
                      : snap.hasData
                      ? '${snap.data} Kelas'
                      : '...';
                  if (snap.hasError) {
                    debugPrint('classes error: ${snap.error}');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row(
                        'Jumlah Kelas',
                        text,
                        last: true,
                        onTap: snap.hasError ? () => setState(_bind) : null,
                      ),
                      if (snap.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${snap.error}',
                            style: const TextStyle(fontSize: 8, color: Ui.red),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _logout,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Ui.redTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Ui.red.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, size: 15, color: Ui.red),
                SizedBox(width: 6),
                Text(
                  'Keluar dari panel admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Ui.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const EduFooter(),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String k;
  final String v;
  final bool last;
  final VoidCallback? onTap;
  const _Row(this.k, this.v, {this.last = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 9))),
          Text(v, style: const TextStyle(fontSize: 9)),
        ],
      ),
    ),
  );
}