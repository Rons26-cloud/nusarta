import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

/// Kebijakan Privasi NUSARTA (mobile), selaras dengan versi web.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Kebijakan Privasi',
      lastUpdated: '6 September 2026',
      sections: [
        (
          title: '1. Pendahuluan',
          paragraphs: [
            'Kebijakan Privasi ini menjelaskan bagaimana NUSARTA mengelola '
                'data saat kamu menggunakan aplikasi dan situs web NUSARTA.',
            'NUSARTA adalah platform pencatatan keuangan pribadi. NUSARTA '
                'bukan bank, tidak menerima simpanan, dan tidak meminta akses '
                'langsung ke rekening bankmu di V1.',
          ],
        ),
        (
          title: '2. Data yang kami proses',
          paragraphs: [
            'Untuk menjalankan fungsi NUSARTA, kami memproses data berikut:',
            '• Informasi akun — email dan informasi sesi autentikasi untuk '
                'mengelola akunmu.',
            '• Catatan keuangan yang kamu masukkan — akun (kas, bank, '
                'e-wallet, kustom), transaksi, budget, dan tujuan keuangan '
                'yang kamu catat secara manual.',
            '• Pengaturan aplikasi — preferensi seperti tema, mata uang, dan '
                'pengaturan auto-lock.',
            '• Metadata terkait keamanan — informasi teknis ringan yang '
                'membantu menjaga keamanan akun.',
          ],
        ),
        (
          title: '3. Cara data diproses',
          paragraphs: [
            'Catatan yang kamu masukkan disimpan dalam infrastruktur cloud '
                'dan dikaitkan dengan akunmu. NUSARTA tidak membaca saldo '
                'rekening atau e-wallet secara otomatis pada V1.',
            'Kami tidak menjual data pribadi atau menggunakan catatan '
                'keuanganmu untuk iklan.',
          ],
        ),
        (
          title: '4. Keamanan data',
          paragraphs: [
            'NUSARTA menerapkan kebijakan akses per pengguna (Row Level '
                'Security), autentikasi yang aman, PIN yang diproses menjadi '
                'hash, dan dukungan biometrik perangkat. Rincian teknis '
                'tersedia di halaman keamanan.',
          ],
        ),
        (
          title: '5. Berbagi data dengan pihak ketiga',
          paragraphs: [
            'NUSARTA menggunakan layanan infrastruktur yang bersifat '
                'mendasar (seperti penyedia cloud). Kami tidak membagikan '
                'catatan keuanganmu kepada pihak lain, kecuali diwajibkan '
                'hukum.',
          ],
        ),
        (
          title: '6. Penyimpanan dan penghapusan',
          paragraphs: [
            'Data tersimpan selama akun aktif. Jika kamu menghapus akun, '
                'catatan yang terkait ikut dihapus. Kamu dapat menghubungi '
                'kami melalui Pusat Bantuan untuk permintaan penghapusan data.',
          ],
        ),
        (
          title: '7. Perubahan kebijakan',
          paragraphs: [
            'Kebijakan ini dapat diperbarui seiring perkembangan produk. '
                'Perubahan penting akan kami informasikan. Dengan terus '
                'menggunakan NUSARTA, kamu menyetujui kebijakan yang berlaku.',
          ],
        ),
        (
          title: '8. Kontak',
          paragraphs: [
            'Pertanyaan terkait privasi dapat dikirim melalui Pusat Bantuan '
                'di aplikasi.',
          ],
        ),
      ],
    );
  }
}
