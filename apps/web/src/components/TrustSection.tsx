import { Reveal } from "./Reveal";
import { trustPoints, trustTagline } from "@/lib/data";

export function TrustSection() {
  return (
    <section className="border-y border-border bg-muted py-16 lg:py-24">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <p className="text-center font-display text-base font-semibold text-foreground sm:text-lg lg:text-xl">
            {trustTagline}
          </p>
        </Reveal>
        <div className="mt-8 lg:mt-12 grid grid-cols-2 gap-6 md:grid-cols-3 lg:grid-cols-5">
          {trustPoints.map((point, i) => {
            const Icon = point.icon;
            return (
              <Reveal key={point.title} delay={i * 0.05}>
                <div className="flex flex-col items-center text-center">
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-card text-brand shadow-sm">
                    <Icon aria-hidden="true" className="h-5 w-5" />
                  </div>
                  <h3 className="mt-4 text-sm font-semibold text-foreground">
                    {point.title}
                  </h3>
                  <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground">
                    {point.description}
                  </p>
                </div>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}