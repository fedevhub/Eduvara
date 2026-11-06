import 'package:flutter_test/flutter_test.dart';
import 'package:eduvara/core/utils/csv_parser.dart';

void main() {
  test('parses quoted commas, escaped quotes, and embedded newlines', () {
    expect(parseCsv('name,description\r\n"Ada, B.","line 1\nline ""2"""'), [
      ['name', 'description'],
      ['Ada, B.', 'line 1\nline "2"'],
    ]);
  });

  test('strips a UTF-8 BOM and ignores blank rows', () {
    expect(parseCsv('\uFEFFname,email\n\nAda,ada@example.com\n'), [
      ['name', 'email'],
      ['Ada', 'ada@example.com'],
    ]);
  });

  test('rejects unmatched quotes', () {
    expect(() => parseCsv('name\n"Ada'), throwsFormatException);
  });
}
