import type { Metadata } from "next";
import { canonicalMetadata } from "@/lib/site";

import { Hero } from "@/components/Hero";
import { FeatureGrid } from "@/components/FeatureGrid";
import { HowItWorksTeaser } from "@/components/HowItWorksTeaser";
import { SecuritySection } from "@/components/SecuritySection";
import { CTASection } from "@/components/CTASection";

export const metadata: Metadata = {
  title: "NUSARTA — Keuanganmu, Dalam Kendalimu",
  description:
    "Aplikasi pengelola keuangan pribadi untuk mencatat pemasukan, pengeluaran, budget, saldo, dan tujuan keuangan dengan mudah.",
  alternates: canonicalMetadata("/"),
};

export default function HomePage() {
  return (
    <>
      <Hero />
      <FeatureGrid />
      <HowItWorksTeaser />
      <SecuritySection />
      <CTASection />
    </>
  );
}
