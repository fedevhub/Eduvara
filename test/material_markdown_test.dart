import 'package:eduvara/components/ui/material_markdown.dart';
import 'package:eduvara/components/ui/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows bold text in the editor without visible Markdown markers',
    (tester) async {
      final controller = MaterialTextEditingController(text: '**lia**');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller, maxLines: 5)),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      final spans = _textSpans(
        controller.buildTextSpan(
          context: tester.element(find.byType(EditableText)),
          style: editable.style,
          withComposing: false,
        ),
      ).toList();
      final bold = spans.firstWhere((span) => span.text == 'lia');
      final markers = spans.where((span) => span.text == '**').toList();

      expect(bold.style?.fontWeight, FontWeight.bold);
      expect(markers, hasLength(2));
      for (final marker in markers) {
        expect(marker.style?.color, Colors.transparent);
        expect(marker.style?.fontSize, lessThan(1));
      }
      expect(controller.text, '**lia**');
      controller.dispose();
    },
  );

  testWidgets('styles selected links, images, and list markers in the editor', (
    tester,
  ) async {
    const source =
        '[tautan](https://example.com)\n[https://eduvara.example](https://eduvara.example)\n![foto](https://example.com/foto.png "foto.png")\n![](https://example.com/no-label.png "Screenshot.png")\n- poin\n1. nomor';
    final controller = MaterialTextEditingController(text: source);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller, maxLines: 5)),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final spans = _textSpans(
      controller.buildTextSpan(
        context: tester.element(find.byType(EditableText)),
        style: editable.style,
        withComposing: false,
      ),
    ).toList();
    final link = spans.firstWhere((span) => span.text == 'tautan');
    final visibleUrl = spans.firstWhere(
      (span) => span.text == 'https://eduvara.example',
    );
    final image = spans.firstWhere((span) => span.text == 'foto');

    expect(link.style?.color, Ui.blue);
    expect(link.style?.decoration, TextDecoration.underline);
    expect(visibleUrl.style?.color, Ui.blue);
    expect(visibleUrl.style?.decoration, TextDecoration.underline);
    expect(image.style?.color, Ui.blue);
    expect(image.style?.fontStyle, FontStyle.italic);
    final hiddenImage = spans.firstWhere(
      (span) => span.text?.contains('no-label') ?? false,
    );
    expect(hiddenImage.style?.color, Colors.transparent);
    expect(hiddenImage.style?.fontSize, lessThan(1));
    expect(hiddenImage.text, contains('Screenshot.png'));
    expect(spans.any((span) => span.text == '• '), isTrue);
    expect(spans.any((span) => span.text == '1. '), isTrue);
    final linkUrl = spans.firstWhere(
      (span) => span.text?.contains('https://example.com') ?? false,
    );
    expect(linkUrl.style?.color, Colors.transparent);
    expect(linkUrl.style?.fontSize, lessThan(1));
    expect(controller.text, source);
    controller.dispose();
  });

  testWidgets('renders material formatting inserted by the toolbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialMarkdown(
            data:
                '**Tebal** *Miring* <u>Garis bawah</u>\n\n- Daftar poin\n\n1. Daftar nomor',
          ),
        ),
      ),
    );

    final spans = <InlineSpan>[
      ...tester
          .widgetList<RichText>(find.byType(RichText))
          .map((richText) => richText.text),
      ...tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.textSpan)
          .whereType<InlineSpan>(),
    ];
    final bold = spans
        .expand(_textSpans)
        .firstWhere((span) => span.toPlainText() == 'Tebal');
    final italic = spans
        .expand(_textSpans)
        .firstWhere((span) => span.toPlainText() == 'Miring');
    final underline = spans
        .expand(_textSpans)
        .firstWhere((span) => span.toPlainText() == 'Garis bawah');
    expect(bold.style?.fontWeight, FontWeight.bold);
    expect(italic.style?.fontStyle, FontStyle.italic);
    expect(underline.style?.decoration, TextDecoration.underline);
    expect(find.text('Daftar poin'), findsOneWidget);
    expect(find.text('Daftar nomor'), findsOneWidget);
  });

  testWidgets('keeps stacked formats without replacing one another', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: MaterialTextEditingController(
              text:
                  '***<u>gabung</u>*** <u>***urutan lain***</u> [**tautan**](https://example.com)',
            ),
          ),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final spans = _textSpans(
      editable.controller.buildTextSpan(
        context: tester.element(find.byType(EditableText)),
        style: editable.style,
        withComposing: false,
      ),
    ).toList();
    final combined = spans.firstWhere((span) => span.text == 'gabung');
    final reversedCombined = spans.firstWhere(
      (span) => span.text == 'urutan lain',
    );
    final linkedBold = spans.firstWhere((span) => span.text == 'tautan');

    expect(combined.style?.fontWeight, FontWeight.bold);
    expect(combined.style?.fontStyle, FontStyle.italic);
    expect(combined.style?.decoration, TextDecoration.underline);
    expect(reversedCombined.style?.fontWeight, FontWeight.bold);
    expect(reversedCombined.style?.fontStyle, FontStyle.italic);
    expect(reversedCombined.style?.decoration, TextDecoration.underline);
    expect(linkedBold.style?.fontWeight, FontWeight.bold);
    expect(linkedBold.style?.decoration, TextDecoration.underline);
    expect(linkedBold.style?.color, Ui.blue);
  });
}

Iterable<TextSpan> _textSpans(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _textSpans(child);
  }
}
