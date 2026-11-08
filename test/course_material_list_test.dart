import 'package:eduvara/components/course/course_material_list.dart';
import 'package:eduvara/models/materi_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('course detail material list shows items without an arrow', (
    tester,
  ) async {
    const material = Materi(
      id: 'material-1',
      courseId: 'course-1',
      title: 'Aljabar',
      content: 'Pengenalan aljabar',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CourseMaterialList(materials: [material], showTrailing: false),
        ),
      ),
    );

    expect(find.text('Aljabar'), findsOneWidget);
    expect(find.text('Pengenalan aljabar'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
