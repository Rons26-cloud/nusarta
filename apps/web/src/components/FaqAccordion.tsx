"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import type { FaqItem } from "@/lib/data";

export function FaqAccordion({ items }: { items: FaqItem[] }) {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <div className="space-y-3">
      {items.map((item, i) => {
        const isOpen = open === i;
        return (
          <div
            key={item.question}
            className="overflow-hidden rounded-2xl border border-border bg-card shadow-sm"
          >
            <button
              onClick={() => setOpen(isOpen ? null : i)}
              aria-expanded={isOpen}
              className="flex w-full items-center justify-between gap-4 px-6 py-5 text-left"
            >
              <span className="font-medium text-foreground">
                {item.question}
              </span>
              <span
                className={`shrink-0 transition-transform duration-200 ${
                  isOpen ? "rotate-45" : ""
                }`}
              >
                <Plus aria-hidden="true" className="h-5 w-5 text-brand" />
              </span>
            </button>
            {isOpen && (
              <div className="px-6 pb-5 text-sm leading-relaxed text-muted-foreground">
                {item.answer}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}