import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { SectionHeading } from "@/components/SectionHeading";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";

export const metadata: Metadata = {
  title: "About",
  description:
    "Tentang NUSARTA: filosofi NUSA (Nusantara) dan ARTA (harta) — platform yang membantu memahami dan mengendalikan keuangan pribadi.",
  alternates: { canonical: "/about" },
};

const philosophy = [
  {
    word: "NUSA",
    meaning:
      "Nusantara dan identitas Indonesia. NUSARTA lahir dari kebutuhan nyata masyarakat Indonesia untuk mengelola uangnya sendiri dengan cara yang dekat dan mudah.",
  },
  {
    word: "ARTA",
    meaning:
      "Nilai, harta, dan pengelolaan kekayaan. NUSARTA hadir untuk membantu kamu mengenali nilai dari setiap pemasukan dan pengeluaran.",
  },
];

export default function AboutPage() {
  return (
    <>
      <PageHero
        eyebrow="Tentang"
        title="NUSARTA — untuk memahami dan mengendalikan keuanganmu"
        description={
          <p>
            NUSARTA adalah personal finance platform dalam bentuk aplikasi
            Android dan situs resmi ini. Kami percaya bahwa memahami keuangan
            adalah langkah pertama untuk mengendalikannya.
          </p>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-8 lg:grid-cols-2">
            {philosophy.map((item, i) => (
              <Reveal key={item.word} delay={i * 0.08}>
                <div className="rounded-3xl border border-border bg-card p-5 sm:p-8 shadow-sm">
                  <p className="inline-flex rounded-xl bg-nusa-primary/10 px-4 py-2 font-display text-2xl font-extrabold tracking-[0.2em] text-brand">
                    {item.word}
                  </p>
                  <p className="mt-5 leading-relaxed text-muted-foreground">
                    {item.meaning}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>

          <div className="mt-14">
            <SectionHeading
              title="NUSARTA, secara utuh"
              description="NUSARTA adalah platform yang membantu kamu memahami dan mengendalikan keuangan pribadi."
            />
            <Reveal className="mx-auto mt-8 max-w-3xl">
              <div className="rounded-3xl bg-card border border-border p-5 sm:p-8 lg:p-12">
                <h3 className="font-display text-2xl font-bold text-foreground lg:text-3xl">
                  Keuanganmu, Dalam Kendalimu.
                </h3>
                <p className="mt-4 leading-relaxed text-muted-foreground">
                  NUSARTA V1 memfokuskan diri pada pencatatan keuangan pribadi
                  yang sederhana, tepat, dan aman. Di masa depan, NUSARTA
                  dirancang untuk berkembang menjadi connected personal finance
                  platform yang terhubung dengan penyedia keuangan resmi — tanpa
                  menulis ulang aplikasi dari nol.
                </p>
                <p className="mt-4 text-sm text-muted-foreground">
                  NUSARTA bukan bank, tidak menerima simpanan, dan tidak
                  menyimpan uang pengguna.
                </p>
              </div>
            </Reveal>
          </div>
        </div>
      </section>

      <CTASection />
    </>
  );
}