import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { SectionHeading } from "@/components/SectionHeading";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import {
  features,
  accountPresets,
  reportKinds,
} from "@/lib/data";

export const metadata: Metadata = {
  title: "Features",
  description:
    "Jelajahi fitur NUSARTA: dashboard keuangan, catatan transaksi, akun keuangan, budget, financial goals, laporan otomatis, kategori, dan pencarian.",
  alternates: { canonical: "/features" },
};

export default function FeaturesPage() {
  return (
    <>
      <PageHero
        eyebrow="Fitur"
        title="Fitur yang dirancang untuk keuangan sehari-hari"
        description={
          <>
            <p>
              NUSARTA V1 berfokus pada pencatatan manual yang rapi dan dapat
              dimengerti siapa pun.
            </p>
            <p>
              Semua angka dihitung dan disimpan dengan benar sehingga laporan
              yang kamu lihat dapat dipercaya.
            </p>
          </>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((feature, i) => {
              const Icon = feature.icon;
              return (
                <Reveal key={feature.title} delay={(i % 4) * 0.05}>
                  <div className="h-full rounded-2xl border border-border bg-card p-6 shadow-sm transition-all hover:-translate-y-1 hover:border-nusa-primary/30 hover:shadow-lg">
                    <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-nusa-primary/10 text-brand">
                      <Icon aria-hidden="true" className="h-5 w-5" />
                    </div>
                    <h3 className="mt-4 font-semibold text-foreground">
                      {feature.title}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                      {feature.description}
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
          <div className="grid gap-10 lg:grid-cols-2">
            <Reveal>
              <SectionHeading
                align="left"
                eyebrow="Akun Keuangan"
                title="Kelola berbagai akun dalam satu tempat"
                description="NUSARTA mendukung pencatatan manual untuk kas, rekening bank, e-wallet, hingga akun kustom."
              />
              <div className="mt-6 flex flex-wrap gap-2">
                {accountPresets.map((name) => (
                  <span
                    key={name}
                    className="rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground"
                  >
                    {name}
                  </span>
                ))}
              </div>
            </Reveal>
            <Reveal delay={0.1}>
              <SectionHeading
                align="left"
                eyebrow="Laporan"
                title="Ringkasan otomatis dalam periode apa pun"
                description="Pilih rentang waktu dan biarkan NUSARTA menghitung pemasukan, pengeluaran, dan tren keuanganmu."
              />
              <div className="mt-6 flex flex-wrap gap-2">
                {reportKinds.map((r) => (
                  <span
                    key={r.label}
                    className="rounded-lg border border-nusa-accent/40 bg-nusa-accent/5 px-3 py-1.5 text-sm font-medium text-accent-foreground"
                  >
                    {r.label}
                  </span>
                ))}
              </div>
            </Reveal>
          </div>
        </div>
      </section>

      <CTASection />
    </>
  );
}