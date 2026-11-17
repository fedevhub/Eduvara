import 'package:eduvara/components/common/student_filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filter panel expands and applies settings', (tester) async {
    var applied = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentFilterPanel(
            classOptions: const ['10', '11', '12'],
            majorOptions: const ['RPL', 'TKJ', 'Mekatronika'],
            selectedClass: null,
            selectedMajor: null,
            sortOrder: 'A-Z',
            onApply: (_, __, ___) {
              applied += 1;
            },
          ),
        ),
      ),
    );

    expect(find.text('Filter'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('student-filter-panel-content')),
      findsNothing,
    );

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('student-filter-panel-content')),
      findsOneWidget,
    );

    await tester.tap(find.text('Atur Filter'));
    await tester.pumpAndSettle();

    expect(applied, 1);
  });
}
