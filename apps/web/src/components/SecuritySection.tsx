import Link from "next/link";
import { Shield, Lock, Fingerprint, Database, Eye, Key } from "lucide-react";
import { Reveal } from "./Reveal";
import { SectionHeading } from "./SectionHeading";

const securityFeatures = [
  {
    icon: Fingerprint,
    title: "Autentikasi Biometrik & PIN",
    description: "PIN 6 digit dan biometrik pada perangkat yang mendukungnya",
  },
  {
    icon: Lock,
    title: "Perlindungan saat sinkronisasi",
    description: "Koneksi terenkripsi melindungi data saat dikirim untuk sinkronisasi",
  },
  {
    icon: Database,
    title: "Akses data pribadi",
    description: "Setiap user hanya dapat mengakses data miliknya sendiri",
  },
  {
    icon: Eye,
    title: "PIN terlindungi",
    description: "PIN tidak disimpan dalam bentuk angka yang dapat dibaca",
  },
  {
    icon: Key,
    title: "Data Hanya Milik Pengguna",
    description: "Kelola catatan melalui akun pribadimu dan pelajari kebijakan privasi kami",
  },
];

export function SecuritySection() {
  return (
    <section className="bg-muted py-16 lg:py-24">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">

          <div>
            <SectionHeading
              align="left"
              eyebrow="Keamanan Data"
              title="Privasi dan keamanan selalu menjadi prioritas"
              description="NUSARTA menggunakan beberapa lapis perlindungan untuk menjaga catatan keuangan pribadimu tetap aman."
            />

            <div className="mt-8 space-y-5">
              {securityFeatures.map((feature, i) => {
                const Icon = feature.icon;
                return (
                  <Reveal key={feature.title} delay={i * 0.08}>
                    <div className="flex items-start gap-4">
                      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-nusa-primary/20 text-accent-foreground">
                        <Icon aria-hidden="true" className="h-6 w-6" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-base text-foreground">
                          {feature.title}
                        </h3>
                        <p className="mt-1 text-sm leading-6 text-muted-foreground">
                          {feature.description}
                        </p>
                      </div>
                    </div>
                  </Reveal>
                );
              })}
            </div>
          </div>

          <aside className="rounded-2xl border border-border bg-card p-6 sm:p-8">
            <Shield aria-hidden="true" className="h-8 w-8 text-brand" />
            <h3 className="mt-5 text-xl font-semibold text-foreground">Catatan pribadi, tetap pribadi.</h3>
            <p className="mt-3 text-sm leading-7 text-muted-foreground">
              Dari membuka aplikasi hingga mengakses transaksi, perlindungan data menjadi bagian dari penggunaan NUSARTA sehari-hari.
            </p>
            <Link href="/security" className="mt-6 inline-flex min-h-11 items-center text-sm font-semibold text-brand underline underline-offset-4">
              Pelajari keamanan NUSARTA
            </Link>
          </aside>
        </div>
      </div>
    </section>
  );
}
