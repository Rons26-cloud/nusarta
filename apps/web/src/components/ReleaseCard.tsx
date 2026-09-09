import { Download, ShieldCheck } from "lucide-react";
import { apkSize, releaseDate, type GithubRelease } from "@/lib/github-releases";

export function ReleaseNotes({ release }: { release: GithubRelease }) {
  if (!release.notes.length) return <p className="mt-3 text-sm text-muted-foreground">Catatan rilis belum tersedia.</p>;
  return <details className="mt-4 text-sm"><summary className="cursor-pointer font-semibold text-brand">Catatan rilis</summary><ul className="mt-3 list-disc space-y-2 break-words pl-5 text-muted-foreground">{release.notes.map((note, index) => <li key={index}>{note}</li>)}</ul></details>;
}

export function ReleaseChecksum({ release }: { release: GithubRelease }) {
  if (!release.sha256 && !release.checksumUrl) return null;
  return <div className="mt-5 rounded-xl border border-border bg-muted p-4"><p className="flex items-center gap-2 text-sm font-semibold text-foreground"><ShieldCheck aria-hidden="true" className="h-4 w-4 shrink-0 text-brand" />SHA-256</p>{release.sha256 && <p className="mt-2 break-all font-mono text-xs text-muted-foreground">{release.sha256}</p>}{release.checksumUrl && <a href={release.checksumUrl} className="mt-2 inline-flex text-sm font-semibold text-brand hover:underline">Download SHA256SUMS.txt</a>}</div>;
}

export function ReleaseCard({ release, latest = false }: { release: GithubRelease; latest?: boolean }) {
  return <article className="min-w-0 rounded-2xl border border-border bg-card p-5 shadow-sm sm:p-6"><div className="flex flex-wrap items-start justify-between gap-4"><div className="min-w-0"><div className="flex flex-wrap items-center gap-3"><h2 className="break-words text-xl font-semibold text-foreground">NUSARTA v{release.version}</h2>{latest && <span className="rounded-full bg-nusa-primary/10 px-3 py-1 text-xs font-semibold text-brand">Versi terkini</span>}</div><p className="mt-2 text-sm text-muted-foreground"><time dateTime={release.publishedAt}>{releaseDate(release.publishedAt)}</time> &middot; {apkSize(release.apkSize)}</p><p className="mt-1 text-xs text-muted-foreground">NUSARTA.apk</p></div><a href={release.apkUrl} aria-label={`Download APK v${release.version}`} className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-nusa-gold px-5 py-3 text-sm font-semibold text-nusa-deepest transition-colors hover:bg-nusa-goldlight"><Download aria-hidden="true" className="h-4 w-4" />Download APK</a></div><ReleaseNotes release={release} /><ReleaseChecksum release={release} /></article>;
}
