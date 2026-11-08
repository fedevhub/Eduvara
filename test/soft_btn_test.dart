import 'package:eduvara/components/ui/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SoftBtn invokes its tap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoftBtn(label: 'Detail', onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Detail'));
    expect(tapped, isTrue);
  });

  testWidgets('PageTitle add button invokes its callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageTitle('Manajemen Course', onAdd: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    expect(tapped, isTrue);
  });
}
