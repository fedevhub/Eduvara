import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) => EduScaffold(
    bottom: const EduBottomNav(role: 'teacher', current: 4),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text('Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        const Center(child: DarkAvatar(size: 64)),
        const SizedBox(height: 8),
        const Center(
          child: Text('Budi Santoso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        const Center(
          child: Text('budi.santoso@eduvara.id', style: TextStyle(fontSize: 10, color: Ui.muted)),
        ),
        const SizedBox(height: 16),
        const EduCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              _Row('Role', 'Guru'),
              _Row('Mapel', 'Matematika'),
              _Row('Status', 'Aktif', last: true),
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
          onTap: () async {
            final ok = await showConfirmWarning(
              context,
              title: 'Keluar dari Eduvara?',
              primary: 'Ya, Keluar',
            );
            if (ok && context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (r) => false);
            }
          },
        ),
      ],
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
      border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
    ),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
        Text(v, style: const TextStyle(fontSize: 10, color: Ui.muted)),
      ],
    ),
  );
}
