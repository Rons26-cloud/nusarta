import type { Metadata } from "next";
import { canonicalMetadata } from "@/lib/site";
import { Fingerprint, ShieldCheck, Smartphone, Lock } from "lucide-react";
import { PageHero } from "@/components/PageHero";
import { SectionHeading } from "@/components/SectionHeading";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import { howItWorksSteps } from "@/lib/data";

export const metadata: Metadata = {
  title: "How It Works",
  description:
    "Cara kerja NUSARTA: buat akun, tambahkan akun keuangan, catat pemasukan dan pengeluaran secara manual, lalu pantau laporan otomatis.",
  alternates: canonicalMetadata("/how-it-works"),
};

export default function HowItWorksPage() {
  return (
    <>
      <PageHero
        eyebrow="Cara Kerja"
        title="Sederhana, transparan, dikendalikan olehmu"
        description={
          <>
            <p>
              NUSARTA V1 menggunakan pencatatan manual. Kamu mencatat setiap
              pemasukan dan pengeluaran sesuai kejadian sebenarnya.
            </p>
            <p>
              NUSARTA tidak membaca saldo rekening secara otomatis — angka yang
              kamu lihat adalah catatan yang kamu kelola sendiri.
            </p>
          </>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-10 lg:grid-cols-2">
            {howItWorksSteps.map((step, i) => {
              const Icon = step.icon;
              return (
                <Reveal key={step.title} delay={i * 0.06}>
                  <div className="flex gap-5 rounded-2xl border border-border bg-card p-6 shadow-sm">
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-nusa-primary text-on-brand">
                      <Icon aria-hidden="true" className="h-6 w-6" />
                    </div>
                    <div>
                      <p className="text-xs font-bold uppercase tracking-widest text-accent-foreground">
                        Langkah {i + 1}
                      </p>
                      <h3 className="mt-1 font-semibold text-foreground">
                        {step.title}
                      </h3>
                      <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                        {step.description}
                      </p>
                    </div>
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
            eyebrow="Membuka Aplikasi"
            title="Biometric atau PIN — pilihan tetap di tanganmu"
            description="Pada perangkat yang mendukung, NUSARTA dapat dibuka menggunakan biometric authentication milik perangkatmu, seperti fingerprint atau face authentication."
          />

          <Reveal className="mx-auto mt-8 lg:mt-12 max-w-3xl">
            <div className="rounded-2xl border border-border bg-card p-6">
              <div className="grid gap-6 sm:grid-cols-2">
                <div className="rounded-xl bg-nusa-primary/5 p-5">
                  <div className="flex items-center gap-2 font-semibold text-foreground">
                    <Smartphone aria-hidden="true" className="h-4 w-4 text-brand" />
                    Membuka dengan Biometric
                  </div>
                  <ol className="mt-4 space-y-3 text-sm text-muted-foreground">
                    <li className="flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-nusa-primary text-[10px] font-bold text-on-brand">
                        1
                      </span>
                      Buka aplikasi
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-nusa-primary text-[10px] font-bold text-on-brand">
                        2
                      </span>
                      <Fingerprint aria-hidden="true" className="h-4 w-4" /> Biometric
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-nusa-primary text-[10px] font-bold text-on-brand">
                        3
                      </span>
                      Dashboard
                    </li>
                  </ol>
                </div>
                <div className="rounded-xl bg-nusa-accent/5 p-5">
                  <div className="flex items-center gap-2 font-semibold text-foreground">
                    <Lock aria-hidden="true" className="h-4 w-4 text-accent-foreground" />
                    Membuka dengan PIN
                  </div>
                  <ol className="mt-4 space-y-3 text-sm text-muted-foreground">
                    <li className="flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-nusa-accent text-[10px] font-bold text-nusa-deepest">
                        1
                      </span>
                      Buka aplikasi
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-nusa-accent text-[10px] font-bold text-nusa-deepest">
                        2
                      </span>
                      PIN 6 digit
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-nusa-accent text-[10px] font-bold text-nusa-deepest">
                        3
                      </span>
                      Dashboard
                    </li>
                  </ol>
                </div>
              </div>

              <div className="mt-6 rounded-xl border border-border bg-muted p-4 text-sm leading-relaxed text-muted-foreground">
                <p className="flex items-center gap-2 font-medium">
                  <ShieldCheck aria-hidden="true" className="h-4 w-4 text-brand" />
                  Perlu diketahui
                </p>
                <p className="mt-2">
                  Jika biometrik gagal atau tidak tersedia, kamu tetap bisa
                  membuka NUSARTA menggunakan PIN. Biometric{" "}
                  <strong>tidak diminta</strong> setiap kali kamu mencatat
                  transaksi — cukup saat membuka aplikasi.
                </p>
              </div>
            </div>
          </Reveal>
        </div>
      </section>

      <CTASection />
    </>
  );
}
