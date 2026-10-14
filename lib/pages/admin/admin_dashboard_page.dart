import 'package:flutter/material.dart';

import '../../components/ui/kit.dart';
import '../../core/routes/route_names.dart';
import '../../core/mock/mock_data.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/quiz_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../models/quiz_model.dart';
import '../../models/notification_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _userRepository = UserRepository();
  final _courseRepository = CourseRepository();
  final _quizRepository = QuizRepository();
  final _notificationRepository = NotificationRepository();

  List<UserModel> _users = [];
  List<Course> _courses = [];
  List<Quiz> _quizzes = [];
  List<NotificationModel> _notifications = [];

  bool _loading = true;

  int get _totalSiswa => _users.where((user) => user.role == 'student').length;

  int get _totalGuru => _users.where((user) => user.role == 'teacher').length;

  int get _totalKursus => _courses.length;

  int get _totalQuiz => _quizzes.length;

  int get _unreadNotifications =>
      _notifications.where((item) => !item.read).length;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        _userRepository.getUsers(),
        _courseRepository.getCourses(),
        _quizRepository.getQuizzes(),
        _notificationRepository.getNotifications(),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0] as List<UserModel>;
        _courses = results[1] as List<Course>;
        _quizzes = results[2] as List<Quiz>;
        _notifications = results[3] as List<NotificationModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data dashboard.')),
      );
    }
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteNames.adminNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return EduScaffold(
      bottom: const EduBottomNav(role: 'admin', current: 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel Admin', style: TextStyle(fontSize: 11)),
                    Text(
                      'Ahmad Fajar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              _NotificationButton(
                count: _unreadNotifications,
                onTap: _openNotifications,
              ),

              const SizedBox(width: 10),
              const DarkAvatar(size: 34),
            ],
          ),

          const SizedBox(height: 14),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: StatBox(
                    value: '$_totalSiswa',
                    label: 'Total Siswa',
                    icon: Icons.groups_outlined,
                    tall: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatBox(
                    value: '$_totalGuru',
                    label: 'Total Guru',
                    icon: Icons.co_present_outlined,
                    tall: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatBox(
                    value: '$_totalKursus',
                    label: 'Total Kursus',
                    icon: Icons.menu_book_outlined,
                    tall: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatBox(
                    value: '$_totalQuiz',
                    label: 'Total Quiz',
                    icon: Icons.fact_check_outlined,
                    tall: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            EduCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completion Rate',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  for (final course in mockCourses)
                    _Rate(course.title, course.percent),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 8),

            if (_notifications.isEmpty)
              const Text('Belum ada aktivitas.')
            else
              for (final notification in _notifications.take(3))
                _Activity(notification.title, notification.date),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 27,
            color: Ui.navy,
          ),
          if (count > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(3),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  final String label;
  final int value;

  const _Rate(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 9))),
              Text(
                '$value%',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Ui.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ProgressLine(value: (value / 100).clamp(0.0, 1.0), height: 5),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  final String title;
  final String time;

  const _Activity(this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EduCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Ui.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 8, color: Ui.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
