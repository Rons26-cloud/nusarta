import type { Metadata } from "next";
import { canonicalMetadata } from "@/lib/site";
import { LegalLayout, LegalSection } from "@/components/LegalLayout";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "Kebijakan privasi NUSARTA: bagaimana data akun, catatan keuangan, dan pengaturan aplikasi dikelola dan dilindungi.",
  alternates: canonicalMetadata("/privacy"),
};

export default function PrivacyPage() {
  return (
    <LegalLayout title="Kebijakan Privasi" lastUpdated="6 September 2026">
      <LegalSection title="1. Pendahuluan">
        <p>
          Kebijakan Privasi ini menjelaskan bagaimana NUSARTA mengelola data
          saat kamu menggunakan aplikasi dan situs web NUSARTA.
        </p>
        <p>
          NUSARTA adalah platform pencatatan keuangan pribadi. NUSARTA
          bukan bank, tidak menerima simpanan, dan tidak meminta akses langsung
          ke rekening bankmu di V1.
        </p>
      </LegalSection>

      <LegalSection title="2. Data yang kami proses">
        <p>Untuk menjalankan fungsi NUSARTA, kami memproses data berikut:</p>
        <ul className="list-disc space-y-1 pl-5">
          <li>
            <strong>Informasi akun</strong> — email dan informasi sesi autentikasi
            untuk mengelola akunmu.
          </li>
          <li>
            <strong>Catatan keuangan yang kamu masukkan</strong> — akun (kas,
            bank, e-wallet, kustom), transaksi, budget, dan tujuan keuangan yang
            kamu catat secara manual.
          </li>
          <li>
            <strong>Pengaturan aplikasi</strong> — preferensi seperti tema,
            mata uang, dan pengaturan auto-lock.
          </li>
          <li>
            <strong>Metadata terkait keamanan</strong> — informasi teknis ringan
            yang membantu menjaga keamanan akun.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="3. Cara data diproses">
        <p>
          Catatan yang kamu masukkan disimpan dalam infrastruktur cloud
          (Supabase) dan dikaitkan dengan akunmu. NUSARTA tidak membaca saldo
          rekening atau e-wallet secara otomatis pada V1.
        </p>
        <p>
          Kami tidak menjual data pribadi atau menggunakan catatan keuanganmu
          untuk iklan.
        </p>
      </LegalSection>

      <LegalSection title="4. Keamanan data">
        <p>
          NUSARTA menerapkan kebijakan akses per pengguna (Row Level
          Security), autentikasi yang aman, PIN yang diproses menjadi hash, dan
          dukungan biometrik perangkat. Rincian teknis tersedia di halaman
          keamanan.
        </p>
      </LegalSection>

      <LegalSection title="5. Berbagi data dengan pihak ketiga">
        <p>
          NUSARTA menggunakan layanan infrastruktur yang bersifat mendasar
          (seperti penyedia cloud). Kami tidak membagikan catatan keuanganmu
          kepada pihak lain, kecuali diwajibkan hukum.
        </p>
      </LegalSection>

      <LegalSection title="6. Penyimpanan dan penghapusan">
        <p>
          Data tersimpan selama akun aktif. Jika kamu menghapus akun, catatan
          yang terkait ikut dihapus. Kamu dapat menghubungi kami melalui halaman
          kontak untuk permintaan penghapusan data.
        </p>
      </LegalSection>

      <LegalSection title="7. Perubahan kebijakan">
        <p>
          Kebijakan ini dapat diperbarui seiring perkembangan produk. Perubahan
          penting akan kami informasikan. Dengan terus menggunakan NUSARTA,
          kamu menyetujui kebijakan yang berlaku.
        </p>
      </LegalSection>

      <LegalSection title="8. Kontak">
        <p>
          Pertanyaan terkait privasi dapat dikirim melalui halaman kontak.
        </p>
      </LegalSection>
    </LegalLayout>
  );
}
