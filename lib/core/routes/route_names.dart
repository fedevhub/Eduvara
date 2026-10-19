class RouteNames {
  // General
  static const splash = '/';
  static const login = '/login';

  // Admin
  static const adminDashboard = '/admin/dashboard';
  static const adminCourses = '/admin/courses';
  static const adminCourseDetail = '/admin/courses/detail';
  static const adminCourseForm = '/admin/courses/form';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/detail';
  static const adminUserForm = '/admin/users/form';
  static const adminMaterials = '/admin/materials';
  static const adminMaterialDetail = '/admin/materials/detail';
  static const adminMaterialForm = '/admin/materials/form';
  static const adminQuizzes = '/admin/quizzes';
  static const adminQuizDetail = '/admin/quizzes/detail';
  static const adminQuizForm = '/admin/quizzes/form';
  static const adminQuestionForm = '/admin/quizzes/questions/form';
  static const adminNotifications = '/admin/notifications';
  static const adminProfile = '/admin/profile';

  // Teacher
  static const teacherDashboard = '/teacher/dashboard';
  static const teacherNotifications = '/teacher/notifications';
  static const teacherCourseDetail = '/teacher/courses/detail';
  static const teacherStudentDetail = '/teacher/students/detail';
  static const teacherMaterialForm = '/teacher/materials/form';
  static const teacherQuizForm = '/teacher/quizzes/form';
  static const teacherQuestionForm = '/teacher/quizzes/questions/form';

  // Student
  static const studentDashboard = '/student/dashboard';
  static const studentCourses = '/student/courses';
  static const studentCourseDetail = '/student/courses/detail';
  static const studentMaterialDetail = '/student/materials/detail';
  static const studentQuiz = '/student/quiz';
  static const studentQuestion = '/student/quiz/question';
  static const studentQuizResult = '/student/quiz/result';

  // Redirect berdasarkan role pengguna
  static String dashboardForRole(String role) {
    switch (role) {
      case 'admin':
        return adminDashboard;
      case 'teacher':
        return teacherDashboard;
      case 'student':
        return studentDashboard;
      default:
        throw Exception('Role tidak dikenali: $role');
    }
  }
}
