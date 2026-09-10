import type { Metadata } from "next";
import { ArrowRight, Clock3, HelpCircle, Lightbulb, MessageCircle, ShieldCheck, WalletCards } from "lucide-react";
import { canonicalMetadata, siteUrl } from "@/lib/site";
import { PageHero } from "@/components/PageHero";
import { SectionHeading } from "@/components/SectionHeading";
import Link from "next/link";

const ecosystemLinks = [
  ["NIAGANTARA", "Platform UMKM dan bisnis", "https://niagantara-web.pages.dev/"],
  ["Xyrons Portfolio", "Portfolio developer", "https://my-portfolioo.pages.dev/"],
  ["Xyrons Hub", "Kumpulan tools dan project Xyrons", "https://www.xyronhub.xyz/"],
] as const;

export const metadata: Metadata = {
  title: "Community NUSARTA",
  description: "Community NUSARTA untuk berbagi pengalaman, ide, masukan, dan perkembangan produk.",
  alternates: canonicalMetadata("/community"),
  openGraph: {
    title: "Community NUSARTA",
    description: "Ikuti perkembangan komunitas dan rencana ruang berbagi ide NUSARTA.",
    url: `${siteUrl()}/community`,
    type: "website",
    images: [{ url: "/hero.png", alt: "NUSARTA" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Community NUSARTA",
    description: "Ikuti perkembangan komunitas dan rencana ruang berbagi ide NUSARTA.",
    images: ["/hero.png"],
  },
};

const categories = [
  [MessageCircle, "Diskusi Umum", "Berbagi cerita dan kebiasaan mengatur keuangan."],
  [Lightbulb, "Ide & Saran", "Sampaikan masukan untuk perkembangan NUSARTA."],
  [HelpCircle, "Bantuan Pengguna", "Temukan panduan dan jawaban untuk penggunaan aplikasi."],
  [Clock3, "Update Produk", "Ikuti perubahan dan rencana NUSARTA."],
  [WalletCards, "Tips Keuangan", "Catatan praktis untuk membuat keputusan lebih terarah."],
] as const;

export default function CommunityPage() {
  return <>
    <PageHero eyebrow="Community" title="Community NUSARTA" description={<p>Bertumbuh bersama pengguna NUSARTA. Bagikan pengalaman, ide, dan masukan untuk membuat pengelolaan keuangan terasa lebih dekat.</p>} />
    <section className="py-16 lg:py-24"><div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
      <SectionHeading align="left" eyebrow="Ruang bersama" title="Ruang untuk ide dan pengalamanmu." description="Berikut topik yang sedang kami siapkan. Diskusi dan keanggotaan belum dibuka; ketersediaan kanal masukan akan diumumkan di halaman kontak." />
      <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">{categories.map(([Icon, title, text]) => <article key={title} className="rounded-2xl border border-border bg-card p-6 shadow-sm transition-transform hover:-translate-y-1"><Icon aria-hidden="true" className="h-6 w-6 text-brand" /><h2 className="mt-5 font-semibold text-foreground">{title}</h2><p className="mt-2 text-sm leading-6 text-muted-foreground">{text}</p></article>)}</div>
    </div></section>
    <section className="py-16 lg:py-24"><div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
      <SectionHeading align="left" eyebrow="Ekosistem NUSARTA" title="Tautan komunitas" description="Kenali platform dan project yang terhubung dengan ekosistem NUSARTA." />
      <div className="mt-10 grid gap-4 md:grid-cols-3">{ecosystemLinks.map(([name, description, href]) => <a key={href} href={href} target="_blank" rel="noopener noreferrer" className="group rounded-2xl border border-border bg-card p-6 shadow-sm transition-all hover:-translate-y-1 hover:border-nusa-primary/30 hover:shadow-lg"><span className="text-xs font-semibold uppercase tracking-[0.16em] text-brand">Ekosistem</span><h2 className="mt-4 font-semibold text-foreground group-hover:text-brand">{name}</h2><p className="mt-2 text-sm leading-6 text-muted-foreground">{description}</p><span className="mt-5 inline-flex text-sm font-semibold text-brand">Kunjungi situs <ArrowRight aria-hidden="true" className="ml-1 h-4 w-4" /></span></a>)}</div>
    </div></section>    <section className="bg-muted py-16 lg:py-24"><div className="mx-auto grid w-full max-w-7xl gap-8 px-4 sm:px-6 lg:grid-cols-[1.15fr_.85fr] lg:px-8"><div><SectionHeading align="left" eyebrow="Kirim Saran" title="Punya ide untuk NUSARTA?" description="Formulir komunitas dan kanal masukan sedang disiapkan. Pantau halaman kontak untuk informasi ketersediaannya." /><Link href="/contact" className="mt-7 inline-flex min-h-12 items-center gap-2 rounded-full bg-nusa-gold px-5 py-3 text-sm font-semibold text-nusa-deepest hover:bg-nusa-goldlight">Lihat informasi kontak <ArrowRight aria-hidden="true" className="h-4 w-4" /></Link></div><aside className="rounded-2xl border border-border bg-card p-6 sm:p-8"><ShieldCheck aria-hidden="true" className="h-7 w-7 text-brand" /><h2 className="mt-5 text-xl font-semibold text-foreground">Community sedang dikembangkan</h2><p className="mt-3 text-sm leading-6 text-muted-foreground">Kami akan membuka ruang interaksi ketika moderasi dan pengalaman pengguna sudah siap. Sampai saat itu, informasi produk tetap tersedia di halaman resmi NUSARTA.</p></aside></div></section>
  </>;
}
