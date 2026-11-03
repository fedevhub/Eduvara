import 'package:flutter_test/flutter_test.dart';

import 'package:eduvara/core/utils/formatters.dart';

void main() {
  test('initials use the first letters of the first two name parts', () {
    expect(Formatters.initials('Budi Santoso'), 'BS');
    expect(Formatters.initials('  Budi   Santoso  '), 'BS');
  });

  test('initials handle single-word and empty names', () {
    expect(Formatters.initials('Budi'), 'BU');
    expect(Formatters.initials(''), '');
  });
}
