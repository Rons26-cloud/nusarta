import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import { features } from "@/lib/data";
import { Reveal } from "./Reveal";
import { SectionHeading } from "./SectionHeading";

export function FeatureGrid() {
  return (
    <section className="py-16 lg:py-24 bg-muted">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="Fitur Utama NUSARTA"
          align="left"
          title="Keuangan sehari-hari, lebih teratur."
          description="Dari mencatat transaksi hingga memantau tujuan keuangan — NUSARTA merapikan seluruhnya."
        />
        <p className="mt-5 max-w-2xl text-sm leading-6 text-muted-foreground">Akun bank dan e-wallet digunakan sebagai catatan manual. NUSARTA tidak mengakses rekening atau memindahkan uangmu.</p>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((feature, i) => {
            const Icon = feature.icon;
            return (
              <Reveal key={feature.title} delay={(i % 4) * 0.06}>
                <div className="h-full rounded-2xl border border-border bg-card p-6 shadow-sm">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-muted text-brand">
                    <Icon aria-hidden="true" className="h-5 w-5" />
                  </div>
                  <h3 className="mt-4 font-semibold text-base text-foreground">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm leading-6 text-muted-foreground">
                    {feature.description}
                  </p>
                </div>
              </Reveal>
            );
          })}
        </div>
        <Reveal className="mt-10 lg:mt-14 text-center">
          <Link
            href="/features"
            className="inline-flex min-h-11 items-center gap-2 text-base font-semibold text-brand transition-colors hover:text-brand"
          >
            Jelajahi semua fitur
            <ArrowUpRight aria-hidden="true" className="h-5 w-5" />
          </Link>
        </Reveal>
      </div>
    </section>
  );
}