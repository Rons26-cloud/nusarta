// Auth errors: Indonesian messages with a generic fallback.
String authErrorMessage(Object? error,
    {String fallback = 'Gagal. Coba lagi.'}) {
  final message = error.toString().toLowerCase();
  if (message.contains('invalid_credentials') ||
      message.contains('invalid login credentials')) {
    return 'Email atau kata sandi salah.';
  }
  if (message.contains('email_exists') ||
      message.contains('already registered')) {
    return 'Email ini sudah terdaftar. Silakan masuk.';
  }
  if (message.contains('weak_password') ||
      message.contains('password should be at least')) {
    return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
  }
  if (message.contains('email_not_confirmed') ||
      message.contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Periksa kotak masuk kamu.';
  }
  if (message.contains('rate_limit') || message.contains('too many requests')) {
    return 'Terlalu banyak percobaan. Tunggu beberapa saat, lalu coba lagi.';
  }
  if (message.contains('network') ||
      message.contains('host lookup') ||
      message.contains('connection')) {
    return 'Tidak ada koneksi internet. Periksa jaringanmu.';
  }
  return fallback;
}
