export type GithubRelease = {
  version: string;
  tag: string;
  title: string;
  notes: string[];
  publishedAt: string;
  apkUrl: string | null;
  apkSize: number | null;
};

const endpoint = "https://api.github.com/repos/Rons26-cloud/nusarta/releases?per_page=100";

function versionOf(tag: unknown): string | null {
  if (typeof tag !== "string") return null;
  const match = tag.trim().replace(/^v/i, "").match(/^(\d+)\.(\d+)\.(\d+)$/);
  return match ? match[0] : null;
}

function compare(a: string, b: string) {
  const pa = a.split(".").map(Number), pb = b.split(".").map(Number);
  return pa[0] - pb[0] || pa[1] - pb[1] || pa[2] - pb[2];
}

export async function getGithubReleases(): Promise<GithubRelease[]> {
  try {
    const response = await fetch(endpoint, { next: { revalidate: 300 }, headers: { Accept: "application/vnd.github+json" } });
    if (!response.ok) return [];
    const raw = await response.json();
    if (!Array.isArray(raw)) return [];
    return raw.flatMap((release) => {
      const version = versionOf(release?.tag_name);
      if (!version || release?.draft || release?.prerelease || typeof release?.published_at !== "string") return [];
      const apk = Array.isArray(release.assets) ? release.assets.find((asset: unknown) => {
        if (!asset || typeof asset !== "object") return false;
        const item = asset as { name?: unknown; browser_download_url?: unknown };
        return item.name === "NUSARTA.apk" && typeof item.browser_download_url === "string";
      }) as { browser_download_url?: string; size?: unknown } | undefined : undefined;
      return [{ version, tag: release.tag_name, title: release.name || `NUSARTA v${version}`, notes: String(release.body || "").split(/\r?\n/).map((line) => line.replace(/^\s*[-*]\s*/, "").trim()).filter(Boolean).slice(0, 12), publishedAt: release.published_at, apkUrl: apk?.browser_download_url ?? null, apkSize: typeof apk?.size === "number" ? apk.size : null }];
    }).sort((a, b) => compare(b.version, a.version));
  } catch { return []; }
}

export async function getLatestGithubRelease() {
  return (await getGithubReleases())[0] ?? null;
}
