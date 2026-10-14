import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

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
        const EduCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              _Row('Nama Sekolah', 'SMK Negeri 8 Malang'),
              _Row('Tahun Ajaran', '2026/2027'),
              _Row('Jumlah Kelas', '30 Kelas', last: true),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final ok = await showConfirmWarning(
              context,
              title: 'Keluar dari panel admin?',
              message: 'Kamu akan keluar dari Eduvara.',
              primary: 'Ya, Keluar',
            );
            if (ok && context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.login,
                (r) => false,
              );
            }
          },
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
  const _Row(this.k, this.v, {this.last = false});

  @override
  Widget build(BuildContext context) => Container(
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
  );
}
