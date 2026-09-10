import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { SectionHeading } from "./SectionHeading";

const experienceSteps = [
  ["01", "Catat", "Catat pemasukan, pengeluaran, atau perpindahan saldo antar akun manual."],
  ["02", "Pantau", "Lihat saldo akun dan arus kas dalam satu dashboard."],
  ["03", "Analisis", "Gunakan laporan untuk memahami pola keuanganmu."],
  ["04", "Atur Budget", "Tetapkan batas pengeluaran per kategori."],
  ["05", "Capai Tujuan", "Pantau progres dana darurat dan tujuan lainnya."],
] as const;

export function HowItWorksTeaser() {
  return (
    <section id="how-it-works" className="bg-background py-16 lg:py-24">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading align="left" eyebrow="Pengalaman NUSARTA" title="Satu aplikasi untuk kendali finansialmu." description="Dari catatan kecil sampai tujuan besar, alurnya dibuat sederhana dan mudah dipahami." />
        <ol className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-5">
          {experienceSteps.map(([number, title, description]) => <li key={title} className="relative min-w-0 border-t border-border pt-5"><span className="text-sm font-semibold text-accent-foreground">{number}</span><h3 className="mt-4 text-base font-semibold text-foreground">{title}</h3><p className="mt-2 text-sm leading-6 text-muted-foreground">{description}</p></li>)}
        </ol>
        <div className="mt-8">
          <Link href="/how-it-works" className="inline-flex min-h-12 items-center gap-2 rounded-full border border-border px-5 py-3 text-sm font-semibold text-brand hover:bg-muted">
            Pelajari cara kerjanya <ArrowRight aria-hidden="true" className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </section>
  );
}
