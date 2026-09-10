import Link from "next/link";
import { ArrowRight, Lightbulb, MessageCircle, Sparkles, WalletCards } from "lucide-react";
import { SectionHeading } from "./SectionHeading";

const categories = [
  { icon: MessageCircle, title: "Diskusi", text: "Berbagi cara mengatur keuangan sehari-hari." },
  { icon: Lightbulb, title: "Saran Fitur", text: "Bantu NUSARTA tumbuh sesuai kebutuhanmu." },
  { icon: WalletCards, title: "Tips Keuangan", text: "Temukan kebiasaan kecil yang lebih terarah." },
  { icon: Sparkles, title: "Update NUSARTA", text: "Ikuti kabar dan perkembangan produk." },
];

export function CommunityPreview() {
  return (
    <section className="relative overflow-hidden bg-nusa-deep py-20 text-nusa-offwhite lg:py-28">
      <div className="pointer-events-none absolute -right-24 top-10 h-64 w-64 rounded-full bg-nusa-gold/10 blur-3xl" />
      <div className="relative mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading align="left" eyebrow="Community NUSARTA" title="Bertumbuh bersama pengguna NUSARTA." description="Tempat berbagi pengalaman, ide, masukan, dan perkembangan produk dengan suasana yang terbuka." light />
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {categories.map(({ icon: Icon, title, text }) => (
            <div key={title}>
              <div className="h-full rounded-2xl border border-white/10 bg-white/[0.06] p-5 transition-colors hover:border-nusa-gold/50 hover:bg-white/[0.1]">
                <Icon aria-hidden="true" className="h-6 w-6 text-nusa-gold" />
                <h3 className="mt-6 font-semibold">{title}</h3>
                <p className="mt-2 text-sm leading-6 text-nusa-offwhite/70">{text}</p>
              </div>
            </div>
          ))}
        </div>
        <Link href="/community" className="mt-9 inline-flex min-h-12 items-center gap-2 rounded-full bg-nusa-gold px-5 py-3 text-sm font-semibold text-nusa-deepest transition-colors hover:bg-nusa-goldlight">
          Jelajahi Community <ArrowRight aria-hidden="true" className="h-4 w-4" />
        </Link>
        <p className="mt-4 text-sm text-nusa-offwhite/70">Ruang diskusi sedang dikembangkan. Pantau halaman kontak untuk ketersediaan kanal masukan.</p>
      </div>
    </section>
  );
}
