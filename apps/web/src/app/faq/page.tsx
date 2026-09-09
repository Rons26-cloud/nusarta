import type { Metadata } from "next";
import { PageHero } from "@/components/PageHero";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import { FaqAccordion } from "@/components/FaqAccordion";
import { faqs } from "@/lib/data";

export const metadata: Metadata = {
  title: "FAQ",
  description:
    "Pertanyaan umum seputar NUSARTA: cara kerja, keamanan, PIN, biometrik, penyimpanan data, dan rencana connected finance.",
  alternates: { canonical: "/faq" },
};

const faqJsonLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: faqs.map((f) => ({
    "@type": "Question",
    name: f.question,
    acceptedAnswer: {
      "@type": "Answer",
      text: f.answer,
    },
  })),
};

export default function FaqPage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />
      <PageHero
        eyebrow="Pertanyaan Umum"
        title="FAQ"
        description={
          <p>
            Jawaban jujur atas pertanyaan yang paling sering diajukan tentang
            NUSARTA.
          </p>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-3xl px-4 sm:px-6 lg:px-8">
          <Reveal>
            <FaqAccordion items={faqs} />
          </Reveal>
        </div>
      </section>

      <CTASection />
    </>
  );
}