import type { Metadata } from "next";
import { canonicalMetadata } from "@/lib/site";
import Link from "next/link";
import Image from "next/image";
import {
  Download,
  ShieldCheck,
  FileCheck,
  Smartphone,
  Calendar,
  Hash,
} from "lucide-react";
import { currentRelease } from "@nusarta/config";
import { PageHero } from "@/components/PageHero";
import { Reveal } from "@/components/Reveal";
import { CTASection } from "@/components/CTASection";
import { releaseChannels } from "@/lib/data";

import { playStoreUrl, releaseDownloadUrl } from "@/lib/site";

export const metadata: Metadata = {
  title: "Download",
  description:
    "Download aplikasi NUSARTA untuk Android. NUSARTA (Nusa Arta) membantu mengelola keuangan pribadi dengan lebih mudah, aman, dan terorganisir.",
  alternates: canonicalMetadata("/download"),
};

export default function DownloadPage() {
  const downloadUrl = releaseDownloadUrl();
  const playsstore = playStoreUrl();
  const downloadAvailable = Boolean(downloadUrl && currentRelease.checksumSha256);

  return (
    <>
      <PageHero
        eyebrow="Download"
        title="Download NUSARTA untuk Android"
        brand={
          <div className="mb-6 flex items-center gap-3">
            <Image src="/nusarta02.png" alt="Logo resmi NUSARTA" width={56} height={56} className="h-14 w-14 shrink-0 object-contain" />
            <div className="min-w-0">
              <p className="text-lg font-bold tracking-tight text-foreground">NUSARTA</p>
              <p className="text-sm text-muted-foreground">Keuanganmu, Dalam Kendalimu.</p>
            </div>
          </div>
        }
        description={
          <p>
            Kelola keuangan pribadi dengan lebih mudah, aman, dan terorganisir bersama NUSARTA.
          </p>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-8 lg:grid-cols-[1.2fr_1fr]">
            <Reveal>
              <div className="rounded-3xl border border-border bg-card p-5 sm:p-8 shadow-sm lg:p-10">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p className="text-sm text-muted-foreground">
                      NUSARTA for Android
                    </p>
                    <p className="font-display text-2xl sm:text-3xl font-bold text-foreground">
                      Versi {currentRelease.version}
                      {currentRelease.buildNumber !== "1" &&
                        `+${currentRelease.buildNumber}`}
                    </p>
                  </div>
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-nusa-primary/10 px-3 py-1.5 text-xs font-semibold text-brand">
                    <span className="h-1.5 w-1.5 rounded-full bg-nusa-primary" />
                    Release
                  </span>
                </div>

                <p className="mt-4 text-sm text-muted-foreground">Nama file: <span className="font-medium text-foreground">{currentRelease.apkFileName}</span></p>
                <p className="mt-1 text-sm text-muted-foreground">Platform: Android <span aria-hidden="true">&middot;</span> Format: APK</p>
                <dl className="mt-8 grid grid-cols-1 gap-x-6 gap-y-5 text-sm sm:grid-cols-2">
                  <div className="flex items-center gap-2.5">
                    <Calendar aria-hidden="true" className="h-4 w-4 shrink-0 text-accent-foreground" />
                    <div>
                      <dt className="text-xs text-muted-foreground">
                        Rilis
                      </dt>
                      <dd className="font-medium text-foreground">
                        {currentRelease.releaseDate}
                      </dd>
                    </div>
                  </div>
                  <div className="flex items-center gap-2.5">
                    <Smartphone aria-hidden="true" className="h-4 w-4 shrink-0 text-accent-foreground" />
                    <div>
                      <dt className="text-xs text-muted-foreground">
                        Android
                      </dt>
                      <dd className="font-medium text-foreground">
                        {currentRelease.minimumAndroidVersion}+
                      </dd>
                    </div>
                  </div>
                  <div className="flex items-center gap-2.5">
                    <FileCheck aria-hidden="true" className="h-4 w-4 shrink-0 text-accent-foreground" />
                    <div>
                      <dt className="text-xs text-muted-foreground">
                        Ukuran berkas
                      </dt>
                      <dd className="font-medium text-foreground">
                        {currentRelease.fileSizeMb === "TBD" || !currentRelease.fileSizeMb
                          ? "—"
                          : currentRelease.fileSizeMb}
                      </dd>
                    </div>
                  </div>
                  <div className="flex items-center gap-2.5">
                    <Hash aria-hidden="true" className="h-4 w-4 shrink-0 text-accent-foreground" />
                    <div>
                      <dt className="text-xs text-muted-foreground">
                        Build
                      </dt>
                      <dd className="font-medium text-foreground">
                        {currentRelease.buildNumber}
                      </dd>
                    </div>
                  </div>
                </dl>

                <div className="mt-8 flex flex-col gap-3 sm:flex-row">
                  {downloadAvailable ? (
                    <a
                      href={downloadUrl ?? undefined}
                      download="NUSARTA.apk"
                      className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-nusa-gold px-5 py-3 text-sm font-semibold text-nusa-deepest shadow-lg shadow-nusa-primary/20 transition-colors hover:bg-nusa-goldlight focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-brand sm:text-base"
                    >
                      <Download aria-hidden="true" className="h-5 w-5" />
                      Download NUSARTA APK
                    </a>
                  ) : (
                    <span className="inline-flex cursor-not-allowed items-center justify-center gap-2 rounded-xl bg-nusa-primary/15 px-8 py-4 font-semibold text-brand">
                      <Calendar aria-hidden="true" className="h-5 w-5" />
                      Segera tersedia
                    </span>
                  )}
                  {playsstore && (
                    <a
                      href={playsstore}
                      className="inline-flex items-center justify-center gap-2 rounded-xl border border-border px-8 py-4 font-semibold text-foreground transition-colors hover:bg-muted"
                    >
                      <Smartphone aria-hidden="true" className="h-5 w-5" />
                      Get it on Google Play
                    </a>
                  )}
                </div>

                {currentRelease.checksumSha256 && (
                  <div className="mt-8 rounded-xl border border-border bg-muted p-4">
                    <h2 className="flex items-center gap-2 text-sm font-semibold text-foreground">
                      <ShieldCheck aria-hidden="true" className="h-4 w-4 text-brand" />
                      Keamanan File
                    </h2>
                    <p className="mt-2 text-xs leading-relaxed text-muted-foreground">SHA-256 berikut dapat digunakan untuk mencocokkan integritas NUSARTA.apk yang diunduh.</p>
                    <p className="mt-2 break-all font-mono text-xs text-muted-foreground">
                      {currentRelease.checksumSha256}
                    </p>
                  </div>
                )}
              </div>
              <section aria-labelledby="install-heading" className="mt-6 rounded-2xl border border-border bg-card p-5 sm:p-8">
                <h2 id="install-heading" className="text-lg font-semibold text-foreground">Cara Instal</h2>
                <ol className="mt-4 list-decimal space-y-3 pl-5 text-sm leading-7 text-muted-foreground">
                  <li>Download NUSARTA.apk.</li>
                  <li>Buka file NUSARTA.apk yang sudah diunduh.</li>
                  <li>Jika Android meminta izin, aktifkan &quot;Install unknown apps&quot; untuk browser/file manager yang digunakan.</li>
                  <li>Lanjutkan instalasi.</li>
                  <li>Setelah selesai, buka NUSARTA.</li>
                </ol>
                <p className="mt-5 rounded-xl bg-muted p-4 text-sm leading-6 text-muted-foreground">
                  Android mungkin menampilkan peringatan karena aplikasi diinstal langsung dari website dan bukan melalui Google Play Store.
                </p>
              </section>
            </Reveal>

            <div className="min-w-0 space-y-6">
              <section className="rounded-2xl border border-border bg-card p-6">
                <h2 className="font-semibold text-foreground">Persyaratan Sistem</h2>
                <ul className="mt-4 list-disc space-y-2 pl-5 text-sm leading-6 text-muted-foreground">
                  <li>Android {currentRelease.minimumAndroidVersion} atau lebih baru (API 26).</li>
                  <li>Koneksi internet untuk fitur online.</li>
                </ul>
              </section>
              <Reveal delay={0.1}>
                <div className="rounded-2xl border border-border bg-card p-6">
                  <h2 className="font-semibold text-foreground">
                    Aman saat mengunduh
                  </h2>
                  <ul className="mt-4 space-y-3 text-sm leading-relaxed text-muted-foreground">
                    <li className="flex gap-2">
                      <ShieldCheck aria-hidden="true" className="h-4 w-4 shrink-0 text-brand" />
                      Unduh NUSARTA hanya dari situs resmi ini atau store
                      resmi.
                    </li>
                    <li className="flex gap-2">
                      <ShieldCheck aria-hidden="true" className="h-4 w-4 shrink-0 text-brand" />
                      Periksa SHA-256 checksum berkas yang kamu unduh bila
                      tersedia.
                    </li>
                    <li className="flex gap-2">
                      <ShieldCheck aria-hidden="true" className="h-4 w-4 shrink-0 text-brand" />
                      Kami tidak pernah meminta kata sandi, PIN, atau data
                      rekening di luar aplikasi.
                    </li>
                  </ul>
                </div>
              </Reveal>

              <Reveal delay={0.15}>
                <div className="rounded-2xl border border-border bg-card p-6">
                  <h2 className="font-semibold text-foreground">
                    Catatan rilis
                  </h2>
                  <ul className="mt-4 space-y-2.5">
                    {currentRelease.notes.map((note) => (
                      <li
                        key={note}
                        className="flex items-start gap-2 text-sm text-muted-foreground"
                      >
                        <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-nusa-accent" />
                        {note}
                      </li>
                    ))}
                  </ul>
                  <Link
                    href="/changelog"
                    className="mt-5 inline-flex items-center gap-1 text-sm font-semibold text-brand hover:underline"
                  >
                    Lihat changelog lengkap
                  </Link>
                </div>
              </Reveal>

              <Reveal delay={0.2}>
                <div className="rounded-2xl border border-border bg-card p-6">
                  <h2 className="font-semibold text-foreground">
                    Saluran rilis
                  </h2>
                  <div className="mt-4 space-y-4">
                    {releaseChannels.map((channel) => (
                      <div
                        key={channel.name}
                        className="flex items-start justify-between gap-3"
                      >
                        <div>
                          <p className="text-sm font-medium text-foreground">
                            {channel.name}
                          </p>
                          <p className="mt-0.5 text-xs text-muted-foreground">
                            {channel.description}
                          </p>
                        </div>
                        <span
                          className={`shrink-0 rounded-full px-2.5 py-1 text-[10px] font-bold uppercase tracking-wide ${
                            channel.active
                              ? "bg-nusa-primary/10 text-brand "
                              : "bg-nusa-neutral/10 text-muted-foreground"
                          }`}
                        >
                          {channel.active ? "Aktif" : "Nonaktif"}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </div>
      </section>

      <CTASection directDownload />
    </>
  );
}
