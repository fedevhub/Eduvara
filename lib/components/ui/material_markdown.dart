import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'kit.dart';

class MaterialTextEditingController extends TextEditingController {
  MaterialTextEditingController({super.text});

  static final _editorToken = RegExp(
    r'^[ \t]*[-*+][ \t]+|^[ \t]*\d+\.[ \t]+|'
    r'!\[([^\]\n]*)\]\((https?://[^)\s]+)(?:\s+"[^"\n]*")?\)|'
    r'\[([^\]\n]+)\]\((https?://[^)\s]+)\)|'
    r'\*\*|\*|<u>|</u>',
    multiLine: true,
  );
  static final _formatMarker = RegExp(r'\*\*|\*|<u>|</u>');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (withComposing && value.composing.isValid) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final spans = <InlineSpan>[];
    var offset = 0;
    var bold = false;
    var italic = false;
    var underline = false;
    for (final match in _editorToken.allMatches(text)) {
      if (match.start > offset) {
        spans.add(
          TextSpan(
            text: text.substring(offset, match.start),
            style: _formatStyle(
              style,
              bold: bold,
              italic: italic,
              underline: underline,
            ),
          ),
        );
      }

      final token = match.group(0)!;
      if (token == '**' || token == '*' || token == '<u>' || token == '</u>') {
        spans.add(_hiddenMarker(token, style));
        switch (token) {
          case '**':
            bold = !bold;
          case '*':
            italic = !italic;
          case '<u>':
            underline = true;
          case '</u>':
            underline = false;
        }
        offset = match.end;
        continue;
      }

      if (token.startsWith('![') || token.startsWith('[')) {
        final isImage = token.startsWith('![');
        final visibleStart = isImage ? 2 : 1;
        final visibleEnd = token.indexOf('](');
        final label = token.substring(visibleStart, visibleEnd);
        if (isImage && label.isEmpty) {
          spans.add(_hiddenMarker(token, style));
          offset = match.end;
          continue;
        }
        final visibleStyle = _formatStyle(
          style,
          bold: bold,
          italic: italic || isImage,
          underline: underline || !isImage,
        ).copyWith(color: Ui.blue);
        spans
          ..add(_hiddenMarker(token.substring(0, visibleStart), style))
          ..addAll(
            _formattedSpans(
              label.isEmpty ? 'gambar' : label,
              visibleStyle,
              bold,
              italic || isImage,
              underline || !isImage,
            ),
          )
          ..add(_hiddenMarker(token.substring(visibleEnd), style));
        offset = match.end;
        continue;
      }

      final isNumbered = RegExp(r'^\d').hasMatch(token);
      final visiblePrefix = isNumbered
          ? token
          : token.replaceFirst(RegExp(r'[-*+]'), '•');
      spans.add(
        TextSpan(
          text: visiblePrefix,
          style: _formatStyle(
            style,
            bold: true,
            italic: italic,
            underline: underline,
          ),
        ),
      );
      offset = match.end;
    }

    if (offset < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(offset),
          style: _formatStyle(
            style,
            bold: bold,
            italic: italic,
            underline: underline,
          ),
        ),
      );
    }
    return TextSpan(style: style, children: spans);
  }

  TextStyle _formatStyle(
    TextStyle? style, {
    required bool bold,
    required bool italic,
    required bool underline,
  }) => (style ?? const TextStyle()).copyWith(
    fontWeight: bold ? FontWeight.bold : null,
    fontStyle: italic ? FontStyle.italic : null,
    decoration: underline ? TextDecoration.underline : null,
  );

  List<InlineSpan> _formattedSpans(
    String value,
    TextStyle? style,
    bool bold,
    bool italic,
    bool underline,
  ) {
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _formatMarker.allMatches(value)) {
      if (match.start > offset) {
        spans.add(
          TextSpan(
            text: value.substring(offset, match.start),
            style: _formatStyle(
              style,
              bold: bold,
              italic: italic,
              underline: underline,
            ),
          ),
        );
      }

      final marker = match.group(0)!;
      spans.add(_hiddenMarker(marker, style));
      switch (marker) {
        case '**':
          bold = !bold;
        case '*':
          italic = !italic;
        case '<u>':
          underline = true;
        case '</u>':
          underline = false;
      }
      offset = match.end;
    }

    if (offset < value.length) {
      spans.add(
        TextSpan(
          text: value.substring(offset),
          style: _formatStyle(
            style,
            bold: bold,
            italic: italic,
            underline: underline,
          ),
        ),
      );
    }
    return spans;
  }

  TextSpan _hiddenMarker(String marker, TextStyle? style) => TextSpan(
    text: marker,
    style: style?.copyWith(
      fontSize: 0.1,
      height: 0.01,
      color: Colors.transparent,
    ),
  );
}

class MaterialMarkdown extends StatelessWidget {
  final String data;
  final double fontSize;
  final MarkdownImageBuilder? imageBuilder;

  const MaterialMarkdown({
    super.key,
    required this.data,
    this.fontSize = 14,
    this.imageBuilder,
  });

  Future<void> _openLink(BuildContext context, String href) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(href);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Link materi tidak valid.')),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Link tidak dapat dibuka.')),
        );
      }
    } catch (e) {
      debugPrint('[MaterialMarkdown] Gagal membuka link: $e');
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Link tidak dapat dibuka.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => MarkdownBody(
    data: data,
    inlineSyntaxes: [_MaterialFormattingSyntax()],
    imageBuilder: imageBuilder,
    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(fontSize: fontSize, height: 1.5),
      listBullet: TextStyle(fontSize: fontSize, height: 1.5),
      a: TextStyle(
        fontSize: fontSize,
        color: Ui.blue,
        decoration: TextDecoration.underline,
      ),
    ),
    builders: {
      'strong': _InlineFormattingBuilder(),
      'em': _InlineFormattingBuilder(),
      'u': _InlineFormattingBuilder(),
    },
    onTapLink: (_, href, __) {
      if (href != null) unawaited(_openLink(context, href));
    },
  );
}

class _MaterialFormattingSyntax extends md.InlineSyntax {
  _MaterialFormattingSyntax()
    : super(r'\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|<u>(.+?)</u>');

  static final _tripleWrapper = RegExp(r'^\*\*\*(.+)\*\*\*$', dotAll: true);
  static final _strongWrapper = RegExp(r'^\*\*(.+)\*\*$', dotAll: true);
  static final _emphasisWrapper = RegExp(r'^\*(.+)\*$', dotAll: true);
  static final _underlineWrapper = RegExp(r'^<u>(.+)</u>$', dotAll: true);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tag = match[1] != null
        ? 'triple'
        : match[2] != null
        ? 'strong'
        : match[3] != null
        ? 'em'
        : 'u';
    final content = match[1] ?? match[2] ?? match[3] ?? match[4]!;
    final element = _formattingElement(tag, content, parser.document);
    parser.addNode(element);
    return true;
  }

  md.Element _formattingElement(
    String tag,
    String content,
    md.Document document,
  ) {
    final children = _nestedFormatting(content, document);
    if (tag == 'triple') {
      return md.Element('strong', [md.Element('em', children)]);
    }
    return md.Element(tag, children);
  }

  List<md.Node> _nestedFormatting(String content, md.Document document) {
    final wrappers = [
      ('triple', _tripleWrapper),
      ('strong', _strongWrapper),
      ('em', _emphasisWrapper),
      ('u', _underlineWrapper),
    ];
    for (final (tag, wrapper) in wrappers) {
      final inner = wrapper.firstMatch(content)?.group(1);
      if (inner != null) {
        return [_formattingElement(tag, inner, document)];
      }
    }
    return md.InlineParser(content, document).parse();
  }
}

class _InlineFormattingBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final inherited = parentStyle ?? DefaultTextStyle.of(context).style;
    final style = _styleForTag(element.tag, inherited);
    final children = element.children
        ?.map((node) => _spanForNode(node, style))
        .toList();
    return Text.rich(TextSpan(style: style, children: children));
  }

  InlineSpan _spanForNode(md.Node node, TextStyle parentStyle) {
    if (node is md.Text) return TextSpan(text: node.text, style: parentStyle);
    if (node is! md.Element) return const TextSpan();

    final style = _styleForTag(node.tag, parentStyle);
    return TextSpan(
      style: style,
      children: node.children
          ?.map((child) => _spanForNode(child, style))
          .toList(),
    );
  }

  TextStyle _styleForTag(String tag, TextStyle style) => switch (tag) {
    'strong' => style.copyWith(fontWeight: FontWeight.bold),
    'em' => style.copyWith(fontStyle: FontStyle.italic),
    'u' => style.copyWith(decoration: TextDecoration.underline),
    _ => style,
  };
}
