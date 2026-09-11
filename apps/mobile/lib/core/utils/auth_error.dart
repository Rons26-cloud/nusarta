import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthConfigurationException implements Exception {}

class AuthProfileException implements Exception {}

String authErrorMessage(Object? error,
    {String fallback = 'Autentikasi belum berhasil. Silakan coba lagi.'}) {
  if (error is AuthConfigurationException) {
    return 'Layanan akun belum siap. Perbarui aplikasi atau coba lagi nanti.';
  }
  if (error is AuthProfileException) {
    return 'Profil akun belum dapat dimuat. Silakan coba masuk kembali.';
  }
  if (error is SocketException ||
      error is ClientException ||
      error is TimeoutException ||
      (error is AuthRetryableFetchException &&
          (int.tryParse(error.statusCode ?? '') ?? 0) < 500)) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  }
  final code = error is AuthException ? error.code : null;
  final status = error is AuthException ? error.statusCode : null;
  // Only classify legacy backend messages; never display them to the user.
  final message = error is AuthException ? error.message.toLowerCase() : '';
  if (code == 'invalid_credentials' ||
      message.contains('invalid login credentials')) {
    return 'Email atau kata sandi salah.';
  }
  if (code == 'user_already_exists' ||
      code == 'email_exists' ||
      message.contains('already registered')) {
    return 'Email ini sudah terdaftar. Silakan masuk.';
  }
  if (code == 'weak_password' ||
      message.contains('password should be at least')) {
    return 'Kata sandi belum memenuhi persyaratan keamanan.';
  }
  if (code == 'email_not_confirmed' ||
      message.contains('email not confirmed')) {
    return 'Email belum diverifikasi. Periksa email Anda untuk melakukan verifikasi.';
  }
  if (status == '429' ||
      (code?.contains('rate_limit') ?? false) ||
      message.contains('rate limit') ||
      message.contains('too many requests')) {
    return 'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.';
  }
  if (code == 'email_address_invalid' ||
      code == 'validation_failed' ||
      message.contains('invalid email')) {
    return 'Alamat email tidak valid. Periksa kembali email Anda.';
  }
  if (code == 'signup_disabled') {
    return 'Pendaftaran sedang tidak tersedia. Silakan coba lagi nanti.';
  }
  if ((int.tryParse(status ?? '') ?? 0) >= 500) {
    return 'Layanan akun sedang mengalami gangguan. Silakan coba lagi nanti.';
  }
  return fallback;
}
