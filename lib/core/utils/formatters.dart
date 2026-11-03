class Formatters {
  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final singleName = parts.first;
      return singleName
          .substring(0, singleName.length > 1 ? 2 : 1)
          .toUpperCase();
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
