import type { ReactNode } from "react";
import { Eyebrow } from "./SectionHeading";

interface PageHeroProps {
  eyebrow: string;
  brand?: ReactNode;
  title: string;
  description?: ReactNode;
}

export function PageHero({ eyebrow, title, description, brand }: PageHeroProps) {
  return (
    <section className="border-b border-border bg-muted py-16 lg:py-24">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="max-w-2xl">
          {brand}
          <Eyebrow>{eyebrow}</Eyebrow>
          <h1 className="mt-5 font-display text-3xl font-extrabold tracking-tight text-foreground sm:text-4xl lg:text-5xl">
            {title}
          </h1>
          {description && (
            <div className="mt-4 space-y-3 text-sm leading-relaxed sm:text-base lg:text-lg text-muted-foreground">
              {description}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}