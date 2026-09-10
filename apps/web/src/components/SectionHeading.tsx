import { cn } from "@nusarta/utils";
import type { ReactNode } from "react";

interface SectionHeadingProps {
  eyebrow?: string;
  title: string;
  description?: string;
  className?: string;
  align?: "center" | "left";
  light?: boolean;
}

export function SectionHeading({
  eyebrow,
  title,
  description,
  className,
  align = "center",
  light = false,
}: SectionHeadingProps) {
  return (
    <div
      className={cn(
        "max-w-2xl",
        align === "center" ? "mx-auto text-center" : "text-left",
        className,
      )}
    >
      {eyebrow && (
        <p className={cn("text-xs font-semibold uppercase tracking-[0.2em]", light ? "text-nusa-gold" : "text-brand")}>
          {eyebrow}
        </p>
      )}
      <h2 className={cn("mt-3 font-display text-2xl font-semibold leading-tight tracking-tight text-balance sm:text-3xl lg:text-4xl", light ? "text-nusa-offwhite" : "text-foreground")}>
        {title}
      </h2>
      {description && (
        <p className={cn("mt-4 text-sm leading-7 sm:text-base", light ? "text-nusa-offwhite/70" : "text-muted-foreground")}>
          {description}
        </p>
      )}
    </div>
  );
}

export function Eyebrow({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <p className={cn("inline-flex items-center rounded-full border border-nusa-gold/30 bg-nusa-gold/10 px-4 py-1.5 text-xs font-bold uppercase tracking-[0.2em] text-accent-foreground", className)}>
      {children}
    </p>
  );
}
