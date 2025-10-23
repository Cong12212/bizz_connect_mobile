class V {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  static String? email(String? v) {
    if (required(v) != null) return 'Required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v!.trim());
    return ok ? null : 'Invalid email';
  }

  static String? min6(String? v) =>
      (v == null || v.length < 6) ? 'Min 6 chars' : null;
}
