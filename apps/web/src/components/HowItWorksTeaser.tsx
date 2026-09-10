import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { howItWorksSteps } from "@/lib/data";
import { SectionHeading } from "./SectionHeading";

export function HowItWorksTeaser() {
  return (
    <section id="how-it-works" className="bg-background py-16 lg:py-24">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading align="left" eyebrow="Cara Kerja NUSARTA" title="Mulai dalam empat langkah sederhana" />
        <ol className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {howItWorksSteps.map((step, i) => {
            const Icon = step.icon;
            return (
              <li key={step.title} className="min-w-0 border-t border-border pt-5 pr-4">
                <div className="flex items-center justify-between gap-3">
                  <Icon aria-hidden="true" className="h-10 w-10 rounded-xl bg-muted p-2 text-brand" />
                  <span className="text-sm font-semibold text-accent-foreground">0{i + 1}</span>
                </div>
                <h3 className="mt-4 text-base font-semibold text-foreground">{step.title}</h3>
                <p className="mt-2 text-sm leading-6 text-muted-foreground">{step.description}</p>
              </li>
            );
          })}
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
