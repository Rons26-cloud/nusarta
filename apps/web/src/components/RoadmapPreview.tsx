import { ArrowRight, Check, Clock3, Sparkles } from "lucide-react";
import Link from "next/link";
import { roadmapPhases } from "@/lib/data";
import { SectionHeading } from "./SectionHeading";

const phaseIcons = [Check, Clock3, Sparkles];

export function RoadmapPreview() {
  return (
    <section className="bg-background py-20 lg:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading align="left" eyebrow="Perjalanan NUSARTA" title="Dibangun bertahap, dengan arah yang jelas." description="Fitur yang sudah tersedia dipisahkan dari rencana pengembangan berikutnya." />
        <div className="mt-10 grid gap-4 lg:grid-cols-3">
          {roadmapPhases.slice(0, 3).map((phase, index) => {
            const Icon = phaseIcons[index];
            return <article key={phase.version} className="rounded-2xl border border-border bg-card p-6 shadow-sm">
              <div className="flex items-center justify-between gap-3"><Icon aria-hidden="true" className="h-5 w-5 text-brand" /><span className="rounded-full bg-muted px-3 py-1 text-xs font-semibold text-muted-foreground">{index === 0 ? "Sekarang" : index === 1 ? "Selanjutnya" : "Masa depan"}</span></div>
              <h3 className="mt-5 text-lg font-semibold text-foreground">{phase.version.replace(/^[^—]+—\s*/, "")}</h3>
              <ul className="mt-4 space-y-2 text-sm leading-6 text-muted-foreground">{phase.items.slice(0, 4).map((item) => <li key={item} className="flex gap-2"><span className="text-brand">•</span>{item}</li>)}</ul>
            </article>;
          })}
        </div>
        <p className="mt-6 text-sm leading-6 text-muted-foreground">V1 masih dalam pengujian perangkat. Koneksi bank, e-wallet, dan transfer uang sungguhan belum tersedia. Rencana dapat berubah mengikuti hasil pengujian.</p>
        <Link href="/roadmap" className="mt-8 inline-flex min-h-11 items-center gap-2 text-sm font-semibold text-brand hover:underline">Lihat roadmap lengkap <ArrowRight aria-hidden="true" className="h-4 w-4" /></Link>
      </div>
    </section>
  );
}
