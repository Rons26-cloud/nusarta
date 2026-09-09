import type { Metadata } from "next";
import { canonicalMetadata } from "@/lib/site";
import { Plus, Wrench, CheckCircle2 } from "lucide-react";
import { PageHero } from "@/components/PageHero";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import { changelog } from "@/lib/data";

export const metadata: Metadata = {
  title: "Changelog",
  description:
    "Catatan rilis NUSARTA: fitur baru, perbaikan, dan peningkatan pada setiap versi.",
  alternates: canonicalMetadata("/changelog"),
};

const hasItems = (list: string[]) => list.length > 0;

export default function ChangelogPage() {
  return (
    <>
      <PageHero
        eyebrow="Release Notes"
        title="Changelog"
        description={
          <p>
            Riwayat rilis NUSARTA disusun dari satu sumber data sehingga selalu
            konsisten dengan versi terbaru.
          </p>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-3xl px-4 sm:px-6 lg:px-8">
          <div className="space-y-12">
            {changelog.map((entry, index) => (
              <Reveal key={`${entry.version}-${entry.build}`} delay={index * 0.05}>
                <article className="rounded-3xl border border-border bg-card p-5 sm:p-8 shadow-sm">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <h2 className="font-display text-2xl font-bold text-foreground">
                      NUSARTA {entry.version}
                      {entry.build && (
                        <span className="text-muted-foreground">{entry.build}</span>
                      )}
                    </h2>
                    <span className="rounded-full bg-nusa-primary/10 px-3 py-1 text-xs font-bold uppercase tracking-wide text-brand">
                      {entry.channel}
                    </span>
                  </div>
                  <p className="mt-2 text-sm text-muted-foreground">
                    Dirilis {entry.date}
                  </p>

                  {hasItems(entry.added) && (
                    <div className="mt-6">
                      <h3 className="flex items-center gap-2 text-sm font-semibold text-foreground">
                        <Plus aria-hidden="true" className="h-4 w-4 text-brand" />
                        Added
                      </h3>
                      <ul className="mt-3 space-y-2">
                        {entry.added.map((item) => (
                          <li
                            key={item}
                            className="flex items-start gap-2 text-sm text-muted-foreground"
                          >
                            <CheckCircle2 aria-hidden="true" className="mt-0.5 h-4 w-4 shrink-0 text-brand" />
                            {item}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}

                  {hasItems(entry.improved) && (
                    <div className="mt-5">
                      <h3 className="flex items-center gap-2 text-sm font-semibold text-foreground">
                        <Wrench aria-hidden="true" className="h-4 w-4 text-accent-foreground" />
                        Improved
                      </h3>
                      <ul className="mt-3 space-y-2">
                        {entry.improved.map((item) => (
                          <li
                            key={item}
                            className="flex items-start gap-2 text-sm text-muted-foreground"
                          >
                            <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-nusa-accent" />
                            {item}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}

                  {hasItems(entry.fixed) && (
                    <div className="mt-5">
                      <h3 className="flex items-center gap-2 text-sm font-semibold text-foreground">
                        <CheckCircle2 aria-hidden="true" className="h-4 w-4 text-brand" />
                        Fixed
                      </h3>
                      <ul className="mt-3 space-y-2">
                        {entry.fixed.map((item) => (
                          <li
                            key={item}
                            className="flex items-start gap-2 text-sm text-muted-foreground"
                          >
                            <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-nusa-primary" />
                            {item}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </article>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <CTASection />
    </>
  );
}
