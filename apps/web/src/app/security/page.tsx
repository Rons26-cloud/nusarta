import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { SectionHeading } from "@/components/SectionHeading";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import { securityPoints } from "@/lib/data";

export const metadata: Metadata = {
  title: "Security & Privacy",
  description:
    "NUSARTA menggunakan autentikasi aman, PIN terenkripsi, dukungan biometrik, dan kebijakan akses data per pengguna untuk melindungi catatan keuanganmu.",
  alternates: { canonical: "/security" },
};

const technicalPoints = [
  {
    title: "Supabase Auth",
    description:
      "Manajemen sesi dan autentikasi dikelola melalui Supabase Auth dengan token sesi yang aman.",
  },
  {
    title: "PIN NUSARTA",
    description:
      "PIN 6 digit dikunci dalam penyimpanan aman perangkat. PIN tidak pernah disimpan sebagai teks asli (plaintext).",
  },
  {
    title: "Biometric unlock",
    description:
      "Fingerprint atau pengenalan wajah perangkat dapat digunakan untuk membuka aplikasi pada perangkat yang mendukung.",
  },
  {
    title: "Secure storage",
    description:
      "Detail sensitif disimpan menggunakan penyimpanan aman perangkat (Android Keystore / iOS Keychain).",
  },
  {
    title: "Row Level Security",
    description:
      "Setiap kueri database dibatasi oleh policy yang hanya mengizinkan akses ke data milik akun yang sedang masuk.",
  },
  {
    title: "Secure session",
    description:
      "Sesi masuk dikelola dengan aman dan dapat berakhir bila perlu.",
  },
  {
    title: "Auto-lock",
    description:
      "Aplikasi dapat terkunci otomatis setelah periode tanpa aktivitas sesuai pengaturan pengguna.",
  },
  {
    title: "Database isolation",
    description:
      "Struktur database memisahkan setiap pengguna, sehingga tidak ada akses silang antar pengguna.",
  },
  {
    title: "No plaintext PIN",
    description:
      "PIN diproses menjadi hash dengan salt unik per perangkat sebelum disimpan.",
  },
  {
    title: "No secret keys in APK",
    description:
      "Aplikasi hanya menggunakan kunci anon (public) untuk cloud. Kunci rahasia server tidak pernah disertakan dalam aplikasi.",
  },
];

export default function SecurityPage() {
  return (
    <>
      <PageHero
        eyebrow="Keamanan & Privasi"
        title="Keamanan dibangun sejak awal"
        description={
          <>
            <p>
              Mengelola keuangan pribadi berarti menjaga datamu tetap aman dan
              hanya bisa diakses olehmu.
            </p>
            <p>
              NUSARTA menggunakan beberapa lapis perlindungan — mulai dari
              autentikasi, PIN, biometrik, hingga kebijakan akses data di
              tingkat database.
            </p>
          </>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {securityPoints.map((point, i) => {
              const Icon = point.icon;
              return (
                <Reveal key={point.title} delay={(i % 4) * 0.05}>
                  <div className="h-full rounded-2xl border border-border bg-card p-6 shadow-sm">
                    <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-nusa-primary/10 text-brand">
                      <Icon aria-hidden="true" className="h-5 w-5" />
                    </div>
                    <h3 className="mt-4 font-semibold text-foreground">
                      {point.title}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                      {point.description}
                    </p>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-muted py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeading
            eyebrow="Transparansi"
            title="Kami tidak membuat janji yang tidak bisa ditepati"
          />
          <Reveal className="mx-auto mt-8 max-w-2xl">
            <div className="rounded-2xl border border-nusa-accent/25 bg-card p-6 text-sm leading-relaxed text-muted-foreground">
              <p className="font-semibold text-accent-foreground">Posisi kami:</p>
              <p className="mt-2">
                Tidak ada sistem keamanan yang sempurna. NUSARTA berkomitmen
                menerapkan praktik keamanan yang baik dan terus memperbarui
                perlindungannya. Kami tidak mengklaim bahwa data &quot;tidak
                mungkin diretas&quot; atau &quot;100% aman tanpa syarat.&quot;
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <SectionHeading
            eyebrow="For Developers"
            title="Technical Security"
            description="Ringkasan teknis untuk developer dan peninjau keamanan."
          />
          <div className="mt-8 lg:mt-12 grid gap-4 md:grid-cols-2">
            {technicalPoints.map((point, i) => (
              <Reveal key={point.title} delay={(i % 2) * 0.05}>
                <div className="rounded-xl border border-border bg-card p-5">
                  <h3 className="font-mono text-sm font-semibold text-brand">
                    {point.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                    {point.description}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <CTASection />
    </>
  );
}