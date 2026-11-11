import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final _db = Supabase.instance.client;
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final profile = await _db
        .from('profiles')
        .select('full_name, role')
        .eq('id', user.id)
        .single();
    if (profile['role'] != 'teacher') {
      throw const AuthException('Profil ini bukan akun guru.');
    }

    final account = await _db
        .from('user')
        .select('username, nip, mapel, status')
        .eq('id_user', user.id)
        .maybeSingle();

    return {
      'name':
          profile['full_name'] ??
          user.userMetadata?['full_name'] ??
          '-',
      'username': account?['nip'] ?? account?['username'] ?? '-',
      'nip': account?['nip'] ?? '-',
      'subject': account?['mapel'] ?? '-',
      'status': account?['status'] ?? '-',
    };
  }

  void _reload() {
    setState(() => _profile = _load());
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
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
    }
  }

  Widget _profileHeader(String name, String username) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.of(context).padding.top + 8,
      20,
      22,
    ),
    decoration: const BoxDecoration(
      gradient: Ui.gradientTop,
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
        Text(
          username,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    bottomNavigationBar: const EduBottomNav(role: 'teacher', current: 4),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
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
                  SoftBtn(
                    label: 'Keluar',
                    icon: Icons.logout,
                    bg: Ui.redTint,
                    fg: Ui.red,
                    height: 38,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        final name = profile['name'].toString();
        return SingleChildScrollView(
          child: Column(
            children: [
              _profileHeader(name, profile['username'].toString()),
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
                          _Row('Username', profile['username'].toString()),
                          const _Row('Role', 'Guru'),
                          _Row('Mapel', profile['subject'].toString()),
                          _Row(
                            'Status',
                            profile['status'].toString(),
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SoftBtn(
                      label: 'Keluar',
                      icon: Icons.logout,
                      bg: Ui.redTint,
                      fg: Ui.red,
                      height: 38,
                      onTap: _logout,
                    ),
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
        Text(v, style: const TextStyle(fontSize: 10, color: Ui.muted)),
      ],
    ),
  );
}
