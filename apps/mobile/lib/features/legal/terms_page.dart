import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

/// Syarat & Ketentuan NUSARTA (mobile), selaras dengan versi web.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Syarat & Ketentuan',
      lastUpdated: '6 September 2026',
      sections: [
        (
          title: '1. Penerimaan persyaratan',
          paragraphs: [
            'Dengan menggunakan NUSARTA (aplikasi dan situs web), kamu '
                'menyetujui Syarat & Ketentuan ini. Jika tidak setuju, mohon '
                'tidak menggunakan layanan kami.',
          ],
        ),
        (
          title: '2. Layanan',
          paragraphs: [
            'NUSARTA menyediakan alat untuk mencatat dan mengelola keuangan '
                'pribadi secara manual. Layanan ini bukan layanan perbankan.',
            '• NUSARTA tidak menyimpan uang pengguna.',
            '• NUSARTA tidak melakukan transfer uang asli pada V1.',
            '• NUSARTA tidak terhubung langsung ke rekening bank pada V1. '
                'Fitur connected-finance hanya akan dihadirkan melalui '
                'integrasi resmi dan legal di masa depan.',
          ],
        ),
        (
          title: '3. Akun dan keamanan',
          paragraphs: [
            'Kamu bertanggung jawab menjaga kerahasiaan email, kata sandi, '
                'dan PIN. NUSARTA dapat menonaktifkan akun bila terjadi '
                'pelanggaran.',
          ],
        ),
        (
          title: '4. Tanggung jawab pengguna',
          paragraphs: [
            'Kamu bertanggung jawab atas kebenaran catatan keuangan yang '
                'kamu masukkan. NUSARTA tidak memberikan nasihat investasi '
                'atau keuangan profesional.',
          ],
        ),
        (
          title: '5. Ketersediaan layanan',
          paragraphs: [
            'Kami berupaya menjaga layanan tetap tersedia dan andal, tetapi '
                'tidak menjamin layanan bebas gangguan atau error. Kami dapat '
                'mengubah atau menghentikan sebagian fitur sewaktu-waktu '
                'dengan pemberitahuan yang sesuai.',
          ],
        ),
        (
          title: '6. Kekayaan intelektual',
          paragraphs: [
            'Nama, logo, dan konten NUSARTA dilindungi hak kekayaan '
                'intelektual. Kamu tidak boleh menggunakannya tanpa izin.',
          ],
        ),
        (
          title: '7. Batasan tanggung jawab',
          paragraphs: [
            'Sejauh diizinkan hukum yang berlaku, NUSARTA tidak bertanggung '
                'jawab atas kerugian tidak langsung yang timbul dari '
                'penggunaan layanan, termasuk kerugian akibat penerimaan '
                'informasi keuangan yang tidak akurat sebagai keputusan '
                'finansial.',
          ],
        ),
        (
          title: '8. Hukum yang berlaku',
          paragraphs: [
            'Persyaratan ini diatur oleh hukum yang berlaku di Republik '
                'Indonesia.',
          ],
        ),
        (
          title: '9. Perubahan persyaratan',
          paragraphs: [
            'Persyaratan dapat diperbarui sewaktu-waktu dan akan diiklankan '
                'di halaman ini dengan tanggal pembaruan. Penggunaan lanjutan '
                'berarti menyetujui perubahan tersebut.',
          ],
        ),
        (
          title: '10. Kontak',
          paragraphs: [
            'Pertanyaan terkait persyaratan dapat dikirim melalui Pusat '
                'Bantuan di aplikasi.',
          ],
        ),
      ],
    );
  }
}
