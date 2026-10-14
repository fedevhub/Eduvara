class Validators {
  static String? required(String? value, [String field = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }
}
