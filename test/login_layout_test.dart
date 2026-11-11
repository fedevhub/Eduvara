import 'package:eduvara/pages/auth/login_page.dart';
import 'package:eduvara/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('login page fits narrow screens without flex overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(180, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password opens the username reset request form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();

    expect(find.text('Ajukan Reset Password'), findsOneWidget);
    expect(find.text('Username'), findsNWidgets(2));
    expect(find.text('Nama lengkap'), findsOneWidget);
    expect(find.text('Kelas (khusus siswa)'), findsOneWidget);
    expect(find.text('Password baru'), findsOneWidget);
    expect(find.textContaining('Email'), findsNothing);

    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('reset-password-field')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('toggle-reset-password-visibility')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
  });

  testWidgets('remember me restores saved username and can clear it', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('remembered_login_username', 'siswa-123');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('login-username-field')))
          .controller!
          .text,
      'siswa-123',
    );
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(const ValueKey('remember-login-checkbox')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('remember-login-checkbox')));
    await tester.pumpAndSettle();
    expect(preferences.getString('remembered_login_username'), isNull);
  });
}
