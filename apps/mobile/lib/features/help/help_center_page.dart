import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOff,
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successContainer,
                  child: Icon(Icons.school_outlined,
                      color: AppColors.brandEmerald),
                ),
                title: const Text('Panduan memulai NUSARTA',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Tutorial interaktif langkah demi langkah',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.neutral),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/tutorial'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successContainer,
                  child:
                      Icon(Icons.link_rounded, color: AppColors.brandEmerald),
                ),
                title: const Text('Panduan menghubungkan akun',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Cara menyambungkan bank & e-wallet dengan aman',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.neutral),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/tutorial/link-account'),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          const _HelpSection(title: 'MEMULAI DENGAN NUSARTA', faqs: [
            _FaqTile(
              question: 'Bagaimana cara membuat akun?',
              answer: 'Daftar di halaman Register menggunakan email dan kata '
                  'sandi, lalu selesaikan verifikasi email agar akun aktif.',
            ),
            _FaqTile(
              question: 'Apa itu PIN aplikasi?',
              answer: 'PIN adalah kunci perangkat untuk membuka NUSARTA. PIN '
                  'disimpan hanya di perangkatmu (tersimpan dengan aman) dan '
                  'tidak dikirim ke server.',
            ),
            _FaqTile(
              question: 'Lupa PIN, bagaimana?',
              answer:
                  'Di layar kunci pilih "Lupa PIN?", masukkan email terdaftar, '
                  'buka kode verifikasi yang dikirim ke email, lalu buat PIN '
                  'baru.',
            ),
          ]),
          const _HelpSection(title: 'PENCATATAN', faqs: [
            _FaqTile(
              question: 'Bagaimana cara menambah transaksi?',
              answer: 'Buka tab Beranda atau Transaksi, tekan ikon "+", pilih '
                  'pemasukan atau pengeluaran, lalu isi jumlah, akun, kategori, '
                  'tanggal, dan catatan. Tekan Simpan.',
            ),
            _FaqTile(
              question: 'Tipe akun apa saja yang tersedia?',
              answer: 'NUSARTA mendukung Kas/Tunai, Bank, E-Wallet, dan akun '
                  'kustom. Setiap transaksi dikaitkan ke salah satu akun.',
            ),
            _FaqTile(
              question: 'Apa fungsi budget dan tujuan keuangan?',
              answer:
                  'Budget membantu memantau batas pengeluaran bulanan. Tujuan '
                  'keuangan dipakai untuk menetapkan target nominal beserta '
                  'tenggat waktu.',
            ),
          ]),
          const _HelpSection(title: 'KEAMANAN & PRIVASI', faqs: [
            _FaqTile(
              question: 'Di mana data keuanganku disimpan?',
              answer:
                  'Catatan keuangan tersimpan di infrastruktur cloud dan hanya '
                  'dapat diakses oleh akunmu (akses per pengguna / Row Level '
                  'Security).',
            ),
            _FaqTile(
              question: 'Bagaimana mengaktifkan biometrik?',
              answer: 'Buka Profil & Pengaturan → Biometrik, ikuti instruksi '
                  'perangkat, lalu gunakan sidik jari atau pemindai wajah saat '
                  'membuka kunci.',
            ),
            _FaqTile(
              question: 'Apa itu Kunci Otomatis?',
              answer: 'Aplikasi otomatis terkunci setelah beberapa waktu tidak '
                  'dipakai sesuai pengaturanmu, untuk melindungi data.',
            ),
            _FaqTile(
              question: 'Bagaimana menghapus akun?',
              answer:
                  'Gunakan menu Hapus Akun di Profil & Pengaturan. Menghapus '
                  'akun menghapus data terkait secara permanen.',
            ),
          ]),
          const _HelpSection(title: 'SINKRONISASI', faqs: [
            _FaqTile(
              question: 'Apakah data sinkron antar perangkat?',
              answer: 'Ya. Akun, transaksi, budget, tujuan, dan pengaturan '
                  'tersimpan di cloud. Setelah masuk di perangkat lain dengan '
                  'akun yang sama, data mengikuti.',
            ),
            _FaqTile(
              question: 'Data tidak tersimpan, apa yang terjadi?',
              answer: 'NUSARTA membutuhkan koneksi internet untuk memuat dan '
                  'menyimpan data. Jika gagal, tarik layar ke bawah '
                  '(refresh) atau coba lagi nanti.',
            ),
          ]),
          const _HelpSection(title: 'DUKUNGAN LAINNYA', faqs: [
            _FaqTile(
              question: 'Di mana melihat kebijakan privasi?',
              answer:
                  'Buka Profil & Pengaturan → Bantuan & Informasi → Kebijakan '
                  'Privasi.',
            ),
            _FaqTile(
              question: 'Bagaimana menjaga keamanan akun?',
              answer: 'Jangan pernah membagikan PIN, kata sandi, atau kode OTP '
                  'kepada siapa pun, dan gunakan email aktif untuk pemulihan '
                  'akun.',
            ),
          ]),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.faqs});
  final String title;
  final List<_FaqTile> faqs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w700)),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < faqs.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                faqs[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      shape: const Border(),
      title: Text(question,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(answer,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.neutral, height: 1.5)),
        ),
      ],
    );
  }
}
