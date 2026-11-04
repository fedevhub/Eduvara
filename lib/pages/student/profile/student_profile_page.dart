import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _db = Supabase.instance.client;
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  bool _isMissingTableError(PostgrestException e) =>
      e.code == 'PGRST205' ||
      e.message.toLowerCase().contains('could not find the table');

  Future<Map<String, dynamic>> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) throw 'Sesi login berakhir, silakan login ulang';

    Map<String, dynamic>? data;
    try {
      data = await _db
          .from('profiles')
          .select('full_name, role, created_at')
          .eq('id', user.id)
          .maybeSingle();
    } on PostgrestException catch (e) {
      if (!_isMissingTableError(e)) rethrow;
    }

    final userData = await _db
        .from('user')
        .select('nama_lengkap, email, status, kelas, created_at')
        .eq('id_user', user.id)
        .maybeSingle();

    return {
      'full_name':
          data?['full_name'] ??
          userData?['nama_lengkap'] ??
          user.userMetadata?['full_name'] ??
          '-',
      'email': user.email ?? userData?['email'] ?? '-',
      'role': data?['role'] ?? 'student',
      'status': userData?['status'],
      'class_name': userData?['kelas'],
      'created_at':
          data?['created_at'] ?? userData?['created_at'] ?? user.createdAt,
    };
  }

  void _reload() {
    final next = _load();
    if (!mounted) return;
    setState(() {
      _profile = next;
    });
  }

  String _role(dynamic raw) {
    final v = raw?.toString().toLowerCase();
    if (v == null || v.isEmpty) return '-';
    if (v == 'student' || v == 'siswa') return 'Siswa';
    if (v == 'teacher' || v == 'guru') return 'Guru';
    if (v == 'admin') return 'Admin';
    return raw.toString();
  }

  String _status(dynamic raw) {
    final v = raw?.toString().toLowerCase();
    if (v == null || v.isEmpty) return '-';
    if (v == 'active' || v == 'aktif') return 'Aktif';
    if (v == 'inactive' || v == 'nonaktif') return 'Nonaktif';
    return raw.toString();
  }

  String _joined(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '-';
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  Future<void> _logout() async {
    final ok = await showConfirmWarning(
      context,
      title: 'Keluar dari Eduvara?',
      primary: 'Ya, Keluar',
    );
    if (!ok || !mounted) return;
    try {
      await _db.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
    }
  }

  Widget _profileHeader(String name, String email) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.of(context).padding.top + 8,
      20,
      22,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFF93B4F8), Ui.blue],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Column(
      children: [
        const Align(alignment: Alignment.centerLeft, child: BackLink()),
        const SizedBox(height: 4),
        DarkAvatar(name: name, size: 64),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(email, style: const TextStyle(fontSize: 10, color: Colors.white)),
      ],
    ),
  );

  Widget _logoutButton() => SoftBtn(
    label: 'Keluar',
    icon: Icons.logout,
    bg: Ui.redTint,
    fg: Ui.red,
    height: 38,
    onTap: _logout,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    bottomNavigationBar: const EduBottomNav(role: 'student', current: 4),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error: tetap beri jalan untuk keluar
        if (snapshot.hasError || snapshot.data == null) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Profil belum dapat dimuat.',
                    style: TextStyle(fontSize: 11, color: Ui.muted),
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                  const SizedBox(height: 8),
                  _logoutButton(),
                ],
              ),
            ),
          );
        }

        final p = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            children: [
              _profileHeader(p['full_name'].toString(), p['email'].toString()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    EduCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Row('Email', p['email'].toString()),
                          _Row('Role', _role(p['role'])),
                          _Row('Status', _status(p['status'])),
                          _Row('Kelas', p['class_name']?.toString() ?? '-'),
                          _Row(
                            'Bergabung',
                            _joined(p['created_at']),
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _logoutButton(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Row extends StatelessWidget {
  final String k;
  final String v;
  final bool last;
  const _Row(this.k, this.v, {this.last = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Ui.muted),
          ),
        ),
      ],
    ),
  );
}
