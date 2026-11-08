// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduvara/app.dart';
import 'package:eduvara/core/routes/route_names.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('Eduvara starts on the splash screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EduvaraApp());

    expect(find.byType(Image), findsOneWidget);
  });

  test('roles resolve to their matching dashboard routes', () {
    expect(RouteNames.dashboardForRole('student'), RouteNames.studentDashboard);
    expect(RouteNames.dashboardForRole('Student'), RouteNames.studentDashboard);
    expect(RouteNames.dashboardForRole('STUDENT'), RouteNames.studentDashboard);
    expect(RouteNames.dashboardForRole('admin'), RouteNames.adminDashboard);
    expect(RouteNames.dashboardForRole('ADMIN'), RouteNames.adminDashboard);
  });
}
