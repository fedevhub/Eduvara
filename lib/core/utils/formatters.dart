class Formatters {
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}
