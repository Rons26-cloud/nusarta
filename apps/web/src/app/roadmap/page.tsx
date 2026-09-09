import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import { roadmapPhases } from "@/lib/data";

export const metadata: Metadata = {
  title: "Roadmap",
  description:
    "Roadmap pengembangan NUSARTA B: personal finance, smart finance, hingga connected finance dengan integrasi resmi.",
  alternates: { canonical: "/roadmap" },
};

const statusStyle = {
  Current: "bg-nusa-primary/10 text-brand ",
  Planned: "bg-nusa-accent/10 text-accent-foreground",
  Future: "bg-nusa-neutral/10 text-muted-foreground",
} as const;

export default function RoadmapPage() {
  return (
    <>
      <PageHero
        eyebrow="Roadmap"
        title="Ke mana NUSARTA akan berkembang"
        description={
          <>
            <p>
              NUSARTA dibangun bertahap dan transparan. Fitur yang berlabel{" "}
              <strong>Planned</strong>, <strong>Future</strong>, atau{" "}
              <strong>Researching</strong> belum tersedia — rencana dapat
              berubah seiring kebutuhan dan regulasi.
            </p>
            <p>
              Koneksi langsung ke bank atau transfer uang asli hanya akan
              dihadirkan melalui integrasi resmi dan legal.
            </p>
          </>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-5xl px-4 sm:px-6 lg:px-8">
          <div className="space-y-10">
            {roadmapPhases.map((phase, index) => (
              <Reveal key={phase.version} delay={index * 0.08}>
                <div className="rounded-3xl border border-border bg-card p-5 sm:p-8 shadow-sm">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <h2 className="font-display text-2xl font-bold text-foreground">
                      {phase.version}
                    </h2>
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wide ${statusStyle[phase.status]}`}
                    >
                      {phase.status === "Current" ? "Saat ini" : phase.status}
                    </span>
                  </div>
                  <ul className="mt-6 grid gap-3 sm:grid-cols-2">
                    {phase.items.map((item) => (
                      <li
                        key={item}
                        className="flex items-start gap-2.5 text-sm text-muted-foreground"
                      >
                        <span
                          className={`mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full ${
                            phase.status === "Current"
                              ? "bg-nusa-primary"
                              : phase.status === "Planned"
                                ? "bg-nusa-accent"
                                : "bg-nusa-neutral"
                          }`}
                        />
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
              </Reveal>
            ))}
          </div>

          <Reveal className="mt-8 lg:mt-12">
            <div className="rounded-2xl border border-nusa-accent/25 bg-nusa-accent/5 p-6 text-sm leading-relaxed text-muted-foreground">
              <p className="font-semibold text-accent-foreground">
                Catatan penting
              </p>
              <p className="mt-2">
                Fitur V2 dan V3 direncanakan untuk masa depan dan belum tersedia
                pada NUSARTA V1. Kami tidak menyebut fitur yang belum ada
                sebagai fitur yang sudah bisa digunakan.
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      <CTASection />
    </>
  );
}