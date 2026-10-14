import 'package:flutter/material.dart';
import '../../../components/ui/kit.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/routes/route_names.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});
  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final items = mockCourses
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return EduScaffold(
      bottom: const EduBottomNav(role: 'admin', current: 2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          PageTitle(
            'Manajemen Course',
            onAdd: () async {
              await Navigator.pushNamed(context, RouteNames.adminCourseForm);

              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 14),
          SearchBox(
            hint: 'Cari Course',
            pill: true,
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 12),
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EduCard(
                padding: const EdgeInsets.all(12),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.adminCourseDetail),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Pill(
                          c.active ? 'Aktif' : 'Nonaktif',
                          kind: c.active ? PillKind.active : PillKind.inactive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.teacher} • ${c.subject}',
                      style: const TextStyle(fontSize: 8.5),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: '${c.students} Siswa  ',
                        style: const TextStyle(fontSize: 8.5),
                        children: [
                          TextSpan(
                            text: '${c.percent}% Selesai',
                            style: const TextStyle(color: Ui.greenDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SoftBtn.edit(
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                RouteNames.adminCourseForm,
                                arguments: c,
                              );

                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SoftBtn.delete(
                            onTap: () async {
                              final ok = await showConfirmDanger(
                                context,
                                title: 'Hapus Course?',
                                message:
                                    '${c.title} akan dihapus dari platform.',
                              );

                              if (!ok || !mounted) return;

                              setState(() {
                                mockCourses.remove(c);
                              });

                              await showSuccessDialog(
                                context,
                                'Course berhasil dihapus!',
                              );
                            },
                          ),
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
