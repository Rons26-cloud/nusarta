import Link from "next/link";
import Image from "next/image";
import { Download, ArrowRight } from "lucide-react";
import styles from "./Hero.module.css";

export function Hero() {
  return (
    <section aria-label="NUSARTA" className={styles.hero + " bg-background"}>
      <h1 className="sr-only">Keuanganmu, Dalam Kendalimu.</h1>
      <Image
        src="/hero.png"
        alt="NUSARTA. Keuanganmu, Dalam Kendalimu. NUSARTA membantu kamu mencatat, memahami, dan mengelola keuangan pribadi dengan mudah, aman, dan modern."
        width={1536}
        height={1024}
        priority
        className="block h-auto w-full object-contain"
        sizes="100vw"
      />

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