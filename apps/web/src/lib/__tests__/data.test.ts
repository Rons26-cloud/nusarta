import { describe, expect, it } from "vitest";

import { siteConfig, navItems } from "@nusarta/config";
import {
  features,
  faqs,
  howItWorksSteps,
  roadmapPhases,
  changelog,
  trustPoints,
} from "@/lib/data";

describe("site config", () => {
  it("keeps brand tagline", () => {
    expect(siteConfig.tagline).toBe("Keuanganmu, Dalam Kendalimu.");
  });

  it("does not hardcode a fake domain", () => {
    expect(siteConfig.url).toBe("");
  });

  it("exposes nav items used by navbar and sitemap", () => {
    expect(navItems.length).toBeGreaterThanOrEqual(6);
  });
});

describe("content data", () => {
  it("has the full feature set", () => {
    expect(features.map((f) => f.title)).toEqual(
      expect.arrayContaining([
        "Dashboard Keuangan",
        "Catatan Transaksi",
        "Akun Keuangan",
        "Budget",
        "Tujuan Keuangan",
        "Laporan Otomatis",
        "Kategori",
        "Search & Filter",
      ]),
    );
  });

  it("has 4 how-it-works steps", () => {
    expect(howItWorksSteps).toHaveLength(4);
  });

  it("has all required FAQ questions", () => {
    const questions = faqs.map((f) => f.question);
    expect(questions).toEqual(
      expect.arrayContaining([
        "Apa itu NUSARTA?",
        "Apakah NUSARTA menyimpan uang saya?",
        "Apakah NUSARTA terhubung langsung ke rekening bank?",
        "Apakah NUSARTA aman?",
      ]),
    );
  });

  it("labels future roadmap work honestly", () => {
    const future = roadmapPhases.find((p) =>
      p.version.startsWith("V2"),
    );
    expect(future?.status).toBe("Planned");
  });

  it("marks V1 as current", () => {
    expect(roadmapPhases[0].status).toBe("Current");
  });

  it("keeps changelog consistent with the released version", () => {
    expect(changelog[0].version).toBe("1.0.0");
    expect(changelog[0].channel).toBe("stable");
  });

  it("has trust points shown on homepage", () => {
    expect(trustPoints).toHaveLength(5);
  });
});