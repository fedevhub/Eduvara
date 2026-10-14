import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/routes/route_names.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  int tab = 0;
  String query = '';

  List<MockUser> get _all => switch (tab) {
    0 => mockSiswa,
    1 => mockGuru,
    _ => mockAdmin,
  };

  @override
  Widget build(BuildContext context) {
    final users = _all
        .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return EduScaffold(
      bottom: const EduBottomNav(role: 'admin', current: 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          PageTitle(
            'Manajemen Pengguna',
            onAdd: () async {
              await Navigator.pushNamed(context, RouteNames.adminUserForm);

              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 14),
          SegTabs(
            labels: [
              'Siswa (${mockSiswa.length})',
              'Guru (${mockGuru.length})',
              'Admin (${mockAdmin.length})',
            ],
            index: tab,
            onChanged: (i) => setState(() {
              tab = i;
              query = '';
            }),
          ),
          const SizedBox(height: 12),
          SearchBox(onChanged: (v) => setState(() => query = v)),
          const SizedBox(height: 12),
          for (final u in users)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EduCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.adminUserDetail,
                  arguments: u,
                ),
                child: Row(
                  children: [
                    const DarkAvatar(size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            u.email,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Ui.muted,
                            ),
                          ),
                          Text(
                            u.info,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Ui.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Pill(
                          u.active ? 'Aktif' : 'Nonaktif',
                          kind: u.active ? PillKind.active : PillKind.inactive,
                        ),
                        const SizedBox(height: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Ui.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
