import 'package:flutter/material.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/splash_page.dart';
import '../../pages/admin/admin_dashboard_page.dart';
import '../../pages/admin/courses/course_detail_page.dart';
import '../../pages/admin/courses/course_form_page.dart';
import '../../pages/admin/courses/course_list_page.dart';
import '../../pages/admin/materials/material_detail_page.dart';
import '../../pages/admin/materials/material_form_page.dart';
import '../../pages/admin/materials/material_list_page.dart';
import '../../pages/admin/notifications/notification_page.dart';
import '../../pages/admin/profile/admin_profile_page.dart';
import '../../pages/admin/quizzes/question_form_page.dart';
import '../../pages/admin/quizzes/quiz_detail_page.dart';
import '../../pages/admin/quizzes/quiz_form_page.dart';
import '../../pages/admin/quizzes/quiz_list_page.dart';
import '../../pages/admin/users/user_detail_page.dart';
import '../../pages/admin/users/user_form_page.dart';
import '../../pages/admin/users/user_list_page.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) =>
      MaterialPageRoute(settings: settings, builder: (_) => _pageFor(settings.name));

  static Widget _pageFor(String? routeName) => switch (routeName) {
    RouteNames.splash => const SplashPage(),
    RouteNames.login => const LoginPage(),
    RouteNames.adminDashboard => const AdminDashboardPage(),
    RouteNames.adminCourses => const CourseListPage(),
    RouteNames.adminCourseDetail => const AdminCourseDetailPage(),
    RouteNames.adminCourseForm => const AdminCourseFormPage(),
    RouteNames.adminUsers => const UserListPage(),
    RouteNames.adminUserDetail => const UserDetailPage(),
    RouteNames.adminUserForm => const UserFormPage(),
    RouteNames.adminMaterials => const AdminMaterialListPage(),
    RouteNames.adminMaterialDetail => const AdminMaterialDetailPage(),
    RouteNames.adminMaterialForm => const AdminMaterialFormPage(),
    RouteNames.adminQuizzes => const AdminQuizListPage(),
    RouteNames.adminQuizDetail => const AdminQuizDetailPage(),
    RouteNames.adminQuizForm => const AdminQuizFormPage(),
    RouteNames.adminQuestionForm => const AdminQuestionFormPage(),
    RouteNames.adminNotifications => const AdminNotificationPage(),
    RouteNames.adminProfile => const AdminProfilePage(),
    _ => const _UnknownRoutePage(),
  };
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.login,
          (route) => false,
        ),
        child: const Text('Kembali ke login'),
      ),
    ),
  );
}
