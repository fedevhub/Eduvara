List<List<String>> parseCsv(String input) {
  final text = input.startsWith('\uFEFF') ? input.substring(1) : input;
  final rows = <List<String>>[];
  final row = <String>[];
  final field = StringBuffer();
  var quoted = false;

  for (var i = 0; i < text.length; i++) {
    final character = text[i];
    if (character == '"') {
      if (quoted && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      row.add(field.toString());
      field.clear();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
        i++;
      }
      row.add(field.toString());
      field.clear();
      if (row.any((value) => value.isNotEmpty)) {
        rows.add(List<String>.of(row));
      }
      row.clear();
    } else {
      field.write(character);
    }
  }

  if (quoted) {
    throw const FormatException('CSV memiliki tanda kutip yang tidak lengkap.');
  }

  row.add(field.toString());
  if (row.any((value) => value.isNotEmpty)) rows.add(row);
  return rows;
}
