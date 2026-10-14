import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_names.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/materi_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/history_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';

class EduvaraApp extends StatelessWidget {
  const EduvaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => MateriProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Eduvara',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: RouteNames.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
