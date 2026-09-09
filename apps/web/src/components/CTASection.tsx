import Link from "next/link";
import { Download } from "lucide-react";
import { currentRelease, getReleaseDownloadUrl } from "@nusarta/config";
import { PhoneMockup } from "./PhoneMockup";

export function CTASection({ directDownload = false }: { directDownload?: boolean }) {
  const DownloadLink = directDownload ? "a" : Link;
  return (
    <section aria-labelledby="download-heading" className="border-y border-border bg-muted py-16 lg:py-24">
      <div className="mx-auto grid w-full max-w-7xl items-center gap-10 px-4 sm:px-6 lg:grid-cols-2 lg:gap-16 lg:px-8">
        <div className="min-w-0 max-w-xl">
          <h2 id="download-heading" className="font-display text-2xl font-semibold leading-tight tracking-tight text-balance text-foreground sm:text-3xl lg:text-4xl">
            Siap Mengelola Keuanganmu?
          </h2>
          <p className="mt-4 max-w-md text-sm leading-7 text-muted-foreground sm:text-base">
            Catat pemasukan, pantau pengeluaran, dan rencanakan keuanganmu dalam satu aplikasi.
          </p>
          <DownloadLink href={directDownload ? getReleaseDownloadUrl() : "/download"} download={directDownload ? currentRelease.apkFileName : undefined} className="mt-7 inline-flex min-h-12 w-full max-w-xs items-center justify-center gap-2 rounded-full bg-nusa-gold px-6 py-3 text-sm font-semibold text-nusa-deepest transition-colors hover:bg-nusa-goldlight sm:w-auto sm:text-base">
            <Download aria-hidden="true" className="h-5 w-5" />
            Download NUSARTA
          </DownloadLink>
          <div className="mt-4 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground sm:text-sm">
            <span>Version {currentRelease.version}</span>
            <span>Android {currentRelease.minimumAndroidVersion}+</span>
          </div>
        </div>
        <div className="flex min-w-0 justify-center lg:justify-end lg:pr-8">
          <PhoneMockup />
        </div>
      </div>
    </section>
  );
}
