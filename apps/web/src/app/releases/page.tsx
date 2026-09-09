import type { Metadata } from "next";
import Link from "next/link";
import { canonicalMetadata } from "@/lib/site";
import { getGithubReleaseCatalog, RELEASES_URL } from "@/lib/github-releases";
import { ReleaseCard } from "@/components/ReleaseCard";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Release NUSARTA", description: "Riwayat versi resmi dan catatan rilis NUSARTA.", alternates: canonicalMetadata("/releases") };

export default async function ReleasesPage() {
  const { releases, status } = await getGithubReleaseCatalog();
  return <main className="mx-auto w-full max-w-4xl px-4 py-16 sm:px-6 lg:px-8"><div className="mb-10"><p className="text-sm font-semibold uppercase tracking-widest text-brand">Release NUSARTA</p><h1 className="mt-3 font-display text-4xl font-bold text-foreground">Riwayat versi</h1><p className="mt-3 text-muted-foreground">Versi stabil resmi NUSARTA. Versi terkini dan semua versi sebelumnya tersedia di sini.</p></div>{releases.length === 0 ? <p role="status" className="rounded-2xl border border-border bg-card p-6 text-muted-foreground">{status === "unavailable" ? "Data rilis belum dapat diperbarui. Silakan coba lagi nanti." : "Belum ada rilis stabil dengan APK yang tersedia."} <a href={RELEASES_URL} className="font-semibold text-brand underline">Lihat GitHub Releases</a></p> : <div className="space-y-6">{releases.map((release, index) => <ReleaseCard key={release.tag} release={release} latest={index === 0} />)}</div>}<Link href="/download" className="mt-8 inline-flex text-sm font-semibold text-brand hover:underline">Kembali ke halaman download</Link></main>;
}
