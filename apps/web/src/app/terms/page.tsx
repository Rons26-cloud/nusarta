import type { Metadata } from "next";
import { canonicalMetadata } from "@/lib/site";
import { LegalLayout, LegalSection } from "@/components/LegalLayout";

export const metadata: Metadata = {
  title: "Terms",
  description:
    "Syarat dan ketentuan penggunaan NUSARTA, aplikasi pencatatan keuangan pribadi.",
  alternates: canonicalMetadata("/terms"),
};

export default function TermsPage() {
  return (
    <LegalLayout title="Syarat & Ketentuan" lastUpdated="6 September 2026">
      <LegalSection title="1. Penerimaan persyaratan">
        <p>
          Dengan menggunakan NUSARTA (aplikasi dan situs web), kamu menyetujui
          Syarat & Ketentuan ini. Jika tidak setuju, mohon tidak menggunakan
          layanan kami.
        </p>
      </LegalSection>

      <LegalSection title="2. Layanan">
        <p>
          NUSARTA menyediakan alat untuk mencatat dan mengelola keuangan pribadi
          secara manual. Layanan ini bukan layanan perbankan.
        </p>
        <ul className="list-disc space-y-1 pl-5">
          <li>NUSARTA tidak menyimpan uang pengguna.</li>
          <li>NUSARTA tidak melakukan transfer uang asli pada V1.</li>
          <li>
            NUSARTA tidak terhubung langsung ke rekening bank pada V1. Fitur
            connected-finance hanya akan dihadirkan melalui integrasi resmi dan
            legal di masa depan.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="3. Akun dan keamanan">
        <p>
          Kamu bertanggung jawab menjaga kerahasiaan email, kata sandi, dan PIN.
          NUSARTA dapat menonaktifkan akun bila terjadi pelanggaran.
        </p>
      </LegalSection>

      <LegalSection title="4. Tanggung jawab pengguna">
        <p>
          Kamu bertanggung jawab atas kebenaran catatan keuangan yang kamu
          masukkan. NUSARTA tidak memberikan nasihat investasi atau keuangan
          profesional.
        </p>
      </LegalSection>

      <LegalSection title="5. Ketersediaan layanan">
        <p>
          Kami berupaya menjaga layanan tetap tersedia dan andal, tetapi tidak
          menjamin layanan bebas gangguan atau error. Kami dapat mengubah atau
          menghentikan sebagian fitur sewaktu-waktu dengan pemberitahuan yang
          sesuai.
        </p>
      </LegalSection>

      <LegalSection title="6. Kekayaan intelektual">
        <p>
          Nama, logo, dan konten NUSARTA dilindungi hak kekayaan intelektual.
          Kamu tidak boleh menggunakannya tanpa izin.
        </p>
      </LegalSection>

      <LegalSection title="7. Batasan tanggung jawab">
        <p>
          Sejauh diizinkan hukum yang berlaku, NUSARTA tidak bertanggung jawab
          atas kerugian tidak langsung yang timbul dari penggunaan layanan,
          termasuk kerugian akibat penerimaan informasi keuangan yang tidak
          akurat sebagai keputusan finansial.
        </p>
      </LegalSection>

      <LegalSection title="8. Hukum yang berlaku">
        <p>
          Persyaratan ini diatur oleh hukum yang berlaku di Republik Indonesia.
        </p>
      </LegalSection>

      <LegalSection title="9. Perubahan persyaratan">
        <p>
          Persyaratan dapat diperbarui sewaktu-waktu dan akan diiklankan di
          halaman ini dengan tanggal pembaruan. Penggunaan lanjutan berarti
          menyetujui perubahan tersebut.
        </p>
      </LegalSection>

      <LegalSection title="10. Kontak">
        <p>
          Pertanyaan terkait persyaratan dapat dikirim melalui halaman kontak.
        </p>
      </LegalSection>
    </LegalLayout>
  );
}
