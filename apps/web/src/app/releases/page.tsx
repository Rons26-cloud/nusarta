import type { Metadata } from "next";
import Link from "next/link";
import { canonicalMetadata } from "@/lib/site";
import { getGithubReleases } from "@/lib/github-releases";

export const metadata: Metadata = { title: "Release NUSARTA", description: "Riwayat versi resmi dan catatan rilis NUSARTA.", alternates: canonicalMetadata("/releases") };

export default async function ReleasesPage() {
  const releases = await getGithubReleases();
  return <main className="mx-auto w-full max-w-4xl px-4 py-16 sm:px-6 lg:px-8"><div className="mb-10"><p className="text-sm font-semibold uppercase tracking-widest text-brand">Release NUSARTA</p><h1 className="mt-3 font-display text-4xl font-bold text-foreground">Riwayat versi</h1><p className="mt-3 text-muted-foreground">Versi stabil resmi dari GitHub NUSARTA.</p></div>{releases.length === 0 ? <p className="rounded-2xl border border-border bg-card p-6 text-muted-foreground">Data release belum dapat dimuat. Silakan coba lagi nanti.</p> : <div className="space-y-6">{releases.map((release) => <article key={release.tag} className="rounded-2xl border border-border bg-card p-6"><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="text-2xl font-semibold text-foreground">NUSARTA v{release.version}</h2><p className="mt-1 text-sm text-muted-foreground">{new Date(release.publishedAt).toLocaleDateString("id-ID", { dateStyle: "long" })}</p></div>{release.apkUrl && <a href={release.apkUrl} className="rounded-xl bg-nusa-gold px-4 py-2 text-sm font-semibold text-nusa-deepest">Download APK</a>}</div><h3 className="mt-5 font-medium text-foreground">{release.title}</h3>{release.notes.length > 0 && <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-muted-foreground">{release.notes.map((note, i) => <li key={`${release.tag}-${i}`}>{note}</li>)}</ul>}</article>)}</div>}<Link href="/download" className="mt-8 inline-flex text-sm font-semibold text-brand hover:underline">Kembali ke halaman download</Link></main>;
}
