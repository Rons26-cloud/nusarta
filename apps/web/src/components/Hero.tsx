import Link from "next/link";
import Image from "next/image";
import { Download, ArrowRight } from "lucide-react";
import styles from "./Hero.module.css";

export function Hero() {
  return (
    <section aria-label="NUSARTA" className={styles.hero + " bg-background"}>
      <h1 className="sr-only">Keuanganmu, Dalam Kendalimu.</h1>
      <link rel="preload" as="image" href="/hero-480.webp" imageSrcSet="/hero-480.webp 480w, /hero-768.webp 768w, /hero-1200.webp 1200w, /hero-1536.webp 1536w" imageSizes="100vw" fetchPriority="high" />
      <picture>
        <source media="(max-width: 600px)" srcSet="/hero-480.webp" />
        <source media="(max-width: 1024px)" srcSet="/hero-768.webp" />
        <source media="(max-width: 1400px)" srcSet="/hero-1200.webp" />
      <Image
        src="/hero-1536.webp"
        alt="NUSARTA. Keuanganmu, Dalam Kendalimu. NUSARTA membantu kamu mencatat, memahami, dan mengelola keuangan pribadi dengan mudah, aman, dan modern."
        width={1536}
        height={1024}
        fetchPriority="high"
className="block h-auto w-full object-contain"
        sizes="100vw"
        unoptimized
      />
      </picture>

      <div className={styles.cta}>
        <Link
          href="/download"
          className={styles.button + " rounded-full bg-nusa-gold font-semibold text-nusa-deepest transition-colors hover:bg-nusa-goldlight focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-nusa-gold"}
        >
          <Download aria-hidden="true" className={styles.icon} />
          Download NUSARTA
        </Link>
        <Link
          href="/how-it-works"
          className={styles.button + " " + styles.secondary + " rounded-full border-nusa-gold bg-transparent font-semibold text-nusa-offwhite transition-colors hover:bg-nusa-gold/10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-nusa-gold"}
        >
          Lihat Cara Kerja
          <ArrowRight aria-hidden="true" className={styles.icon} />
        </Link>
      </div>
    </section>
  );
}