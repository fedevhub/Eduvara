import 'package:eduvara/pages/admin/courses/course_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('major filters are inside the subject dropdown', (tester) async {
    String? selectedSubject;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubjectSelector(
            hint: 'Pilih mata pelajaran',
            value: selectedSubject,
            onChanged: (value) => selectedSubject = value,
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNothing);

    await tester.tap(find.text('Pilih mata pelajaran'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'RPL'), findsOneWidget);
    expect(find.text('Pemrograman'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'TKJ'));
    await tester.pumpAndSettle();

    expect(find.text('Jaringan'), findsOneWidget);
    expect(find.text('Pemrograman'), findsNothing);
    expect(find.text('Matematika'), findsOneWidget);

    await tester.tap(find.text('Jaringan'));
    await tester.pumpAndSettle();

    expect(selectedSubject, 'Jaringan');
  });
}
