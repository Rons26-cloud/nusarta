import Link from "next/link";
import { PhoneMockup } from "./PhoneMockup";
import { Download, ArrowRight } from "lucide-react";
import styles from "./Hero.module.css";

export function Hero() {
  return (
    <section aria-label="NUSARTA" className={styles.hero}>
      <div className={styles.inner}>
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-nusa-gold">Keuangan pribadi, lebih terarah</p>
          <h1 className="mt-6 font-display text-4xl font-semibold leading-[1.15] tracking-tight text-balance sm:text-5xl xl:text-6xl">Keuanganmu,<br /><span className="text-nusa-gold">Dalam Kendalimu.</span></h1>
          <p className="mt-6 max-w-lg text-base leading-8 text-nusa-offwhite/80 sm:text-lg">Catat transaksi, pahami arus kas, dan bangun kebiasaan keuangan yang lebih baik. Semua dalam satu ruang yang terasa milikmu.</p>
          <div className={styles.cta}>
            <Link
              href="/download"
              className={styles.button + " rounded-full bg-nusa-gold font-semibold text-nusa-deepest transition-colors hover:bg-nusa-goldlight focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-nusa-gold"}
            >
              <Download aria-hidden="true" className={styles.icon} />
              Coba APK Test
            </Link>
            <Link
              href="/how-it-works"
              className={styles.button + " " + styles.secondary + " rounded-full border-nusa-gold bg-transparent font-semibold text-nusa-offwhite transition-colors hover:bg-nusa-gold/10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-nusa-gold"}
            >
              Lihat Cara Kerja
              <ArrowRight aria-hidden="true" className={styles.icon} />
            </Link>
          </div>
          <p className="mt-5 text-xs leading-6 text-nusa-offwhite/70">Android 8.0+ &middot; Versi pengujian perangkat</p>
          <p className="mt-6 max-w-lg border-t border-white/15 pt-5 text-sm leading-6 text-nusa-offwhite/70">Pencatatan manual. Tanpa koneksi bank atau transfer uang sungguhan.</p>
        </div>
        <figure className="min-w-0">
          <PhoneMockup className="mx-auto" />
          <figcaption className="mt-5 text-center text-xs text-nusa-offwhite/65">Ilustrasi tampilan &middot; data contoh</figcaption>
        </figure>
      </div>
    </section>
  );
}