export type GithubRelease = {
  version: string;
  tag: string;
  title: string;
  notes: string[];
  publishedAt: string;
  apkUrl: string;
  apkSize: number;
  sha256: string | null;
  checksumUrl: string | null;
};

export type ReleaseCatalog = {
  status: "ready" | "unavailable";
  releases: GithubRelease[];
};

export type GithubTestRelease = {
  tag: string;
  version: string;
  apkName: string;
  title: string;
  publishedAt: string;
  apkUrl: string;
  apkSize: number;
};

export const RELEASES_URL = "https://github.com/Rons26-cloud/nusarta/releases";
export const RELEASE_CACHE_SECONDS = 300;
// v1.0.0 is excluded after the validated device startup failure.
export const EXCLUDED_RELEASE_TAGS = new Set(["v1.0.0"]);
const endpoint = "https://api.github.com/repos/Rons26-cloud/nusarta/releases";
const cacheKey = `${endpoint}?nusarta-catalog-v2`;
const stableVersion = /^v?((?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?)$/;

type RecordValue = Record<string, unknown>;
function record(value: unknown): value is RecordValue {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function assetUrl(asset: RecordValue, tag: string, name: string): string | null {
  if (asset.name !== name || asset.state !== "uploaded" ||
      typeof asset.size !== "number" || !Number.isSafeInteger(asset.size) || asset.size <= 0 ||
      typeof asset.browser_download_url !== "string") return null;
  try {
    const url = new URL(asset.browser_download_url);
    if (url.origin !== "https://github.com" || url.username || url.password || url.search || url.hash ||
        decodeURIComponent(url.pathname) !== `/Rons26-cloud/nusarta/releases/download/${tag}/${name}`) return null;
    return url.href;
  } catch { return null; }
}

function compareVersions(a: string, b: string): number {
  const left = a.split("+")[0].split(".");
  const right = b.split("+")[0].split(".");
  for (let i = 0; i < 3; i++) {
    // Compare digit strings without losing precision on large semver components.
    const difference = left[i].length - right[i].length || left[i].localeCompare(right[i]);
    if (difference) return difference;
  }
  return 0;
}

export function normalizeReleases(raw: unknown): GithubRelease[] {
  if (!Array.isArray(raw)) return [];
  const releases: GithubRelease[] = [];
  const tags = new Set<string>();
  for (const item of raw) {
    if (!record(item) || item.draft !== false || item.prerelease !== false ||
        typeof item.tag_name !== "string" || typeof item.published_at !== "string" ||
        !Number.isFinite(Date.parse(item.published_at)) || !Array.isArray(item.assets)) continue;
    if (EXCLUDED_RELEASE_TAGS.has(item.tag_name)) continue;
    const version = stableVersion.exec(item.tag_name)?.[1];
    if (!version || tags.has(item.tag_name)) continue;
    const apk = item.assets.find((asset) => record(asset) && assetUrl(asset, item.tag_name as string, "NUSARTA.apk"));
    if (!record(apk)) continue;
    const checksum = item.assets.find((asset) => record(asset) && assetUrl(asset, item.tag_name as string, "SHA256SUMS.txt"));
    releases.push({
      version, tag: item.tag_name,
      title: typeof item.name === "string" && item.name.trim() ? item.name : `NUSARTA v${version}`,
      notes: typeof item.body === "string" ? item.body.split(/\r?\n/).map((line) => line.replace(/^\s*[-*#]+\s*/, "").trim()).filter(Boolean) : [],
      publishedAt: item.published_at,
      apkUrl: assetUrl(apk, item.tag_name, "NUSARTA.apk")!,
      apkSize: apk.size as number,
      sha256: typeof apk.digest === "string" && /^sha256:[a-f0-9]{64}$/i.test(apk.digest) ? apk.digest.slice(7).toLowerCase() : null,
      checksumUrl: record(checksum) ? assetUrl(checksum, item.tag_name, "SHA256SUMS.txt") : null,
    });
    tags.add(item.tag_name);
  }
  return releases.sort((a, b) => compareVersions(b.version, a.version) || Date.parse(b.publishedAt) - Date.parse(a.publishedAt));
}

type CachedCatalog = { expiresAt: number; catalog: ReleaseCatalog };
let memory: CachedCatalog | undefined;
let pending: Promise<ReleaseCatalog> | undefined;

// Cloudflare's Cache API needs no R2/KV binding. Node uses the bounded memory
// cache. Pages are dynamic: neither deployment can freeze a build-time release.
function edgeCache(): Cache | undefined {
  return (globalThis as typeof globalThis & { caches?: CacheStorage & { default?: Cache } }).caches?.default;
}

async function loadCatalog(): Promise<ReleaseCatalog> {
  const edge = edgeCache();
  try {
    const cached = await edge?.match(cacheKey);
    if (cached) {
      const entry = await cached.json() as CachedCatalog;
      if (entry.expiresAt > Date.now() && entry.catalog?.status === "ready" && Array.isArray(entry.catalog.releases)) {
        memory = entry;
        return entry.catalog;
      }
    }
  } catch { /* A cache failure must not prevent a fresh GitHub request. */ }

  let catalog: ReleaseCatalog;
  try {
    const raw: unknown[] = [];
    let page = 1;
    const signal = AbortSignal.timeout(10000);
    while (true) {
      const response = await fetch(`${endpoint}?per_page=100&page=${page}`, {
        cache: "no-store", signal,
        headers: { Accept: "application/vnd.github+json", "User-Agent": "NUSARTA-Release-Website", "X-GitHub-Api-Version": "2022-11-28" },
      });
      if (!response.ok) throw new Error("Release service unavailable");
      const items: unknown = await response.json();
      if (!Array.isArray(items)) throw new Error("Invalid release response");
      raw.push(...items);
      if (!response.headers.get("link")?.includes('rel="next"')) break;
      // Construct subsequent URLs ourselves; never follow arbitrary API links.
      if (++page > 100) throw new Error("Release pagination limit exceeded");
    }
    catalog = { status: "ready", releases: normalizeReleases(raw) };
  } catch {
    catalog = { status: "unavailable", releases: [] };
  }
  memory = { catalog, expiresAt: Date.now() + (catalog.status === "ready" ? RELEASE_CACHE_SECONDS : 30) * 1000 };
  if (catalog.status === "ready") {
    try {
      await edge?.put(cacheKey, new Response(JSON.stringify(memory), {
        headers: { "Content-Type": "application/json", "Cache-Control": `public, max-age=${RELEASE_CACHE_SECONDS}` },
      }));
    } catch { /* The bounded memory cache remains available. */ }
  }
  return catalog;
}

export async function getGithubReleaseCatalog(): Promise<ReleaseCatalog> {
  if (memory && memory.expiresAt > Date.now()) return memory.catalog;
  if (!pending) pending = loadCatalog().finally(() => { pending = undefined; });
  return pending;
}

export async function getGithubReleases(): Promise<GithubRelease[]> {
  return (await getGithubReleaseCatalog()).releases;
}

export async function getLatestGithubRelease(): Promise<GithubRelease | null> {
  return (await getGithubReleases())[0] ?? null;
}

// Testing releases have their own channel and never fall back to production.
export function normalizeTestReleases(raw: unknown): GithubTestRelease[] {
  if (!Array.isArray(raw)) return [];
  const releases: GithubTestRelease[] = [];
  for (const item of raw) {
    if (!record(item) || item.draft !== false || item.prerelease !== true ||
        typeof item.tag_name !== "string" || !/^test-v[0-9][0-9A-Za-z.+-]*$/.test(item.tag_name) ||
        typeof item.published_at !== "string" || !Number.isFinite(Date.parse(item.published_at)) ||
        !Array.isArray(item.assets)) continue;
    const version = item.tag_name.slice(5);
    const apkName = "NUSARTA-TEST-" + version + ".apk";
    const apk = item.assets.find((asset) => record(asset) && assetUrl(asset, item.tag_name as string, apkName));
    if (!record(apk)) continue;
    releases.push({
      tag: item.tag_name, version, apkName,
      title: typeof item.name === "string" ? item.name : "NUSARTA " + version,
      publishedAt: item.published_at,
      apkUrl: assetUrl(apk, item.tag_name, apkName)!,
      apkSize: apk.size as number,
    });
  }
  return releases.sort((a, b) => Date.parse(b.publishedAt) - Date.parse(a.publishedAt));
}

const CURRENT_TEST_RELEASE: GithubTestRelease = {
  tag: "test-v1.0.3",
  version: "v1.0.3",
  apkName: "NUSARTA-TEST-v1.0.3.apk",
  title: "NUSARTA v1.0.3 Testing",
  publishedAt: "2026-09-12T12:51:07Z",
  apkUrl: "https://github.com/Rons26-cloud/nusarta/releases/download/test-v1.0.3/NUSARTA-TEST-v1.0.3.apk",
  apkSize: 200085835,
};

export async function getGithubTestRelease(): Promise<GithubTestRelease | null> {
  try {
    const raw: unknown[] = [];
    const signal = AbortSignal.timeout(10000);
    for (let page = 1; page <= 100; page++) {
      // Keep the testing channel live so a newly published prerelease is visible without waiting for a stale framework data-cache entry.
      const response = await fetch(endpoint + "?per_page=100&page=" + page + "&channel=testing-v1", {
        cache: "no-store", signal,
        headers: { Accept: "application/vnd.github+json", "User-Agent": "NUSARTA-Release-Website", "X-GitHub-Api-Version": "2022-11-28" },
      });
      if (!response.ok) return CURRENT_TEST_RELEASE;
      const items: unknown = await response.json();
      if (!Array.isArray(items)) return CURRENT_TEST_RELEASE;
      raw.push(...items);
      if (!response.headers.get("link")?.includes('rel="next"')) return normalizeTestReleases(raw)[0] ?? CURRENT_TEST_RELEASE;
    }
    return CURRENT_TEST_RELEASE;
  } catch {
    return CURRENT_TEST_RELEASE;
  }
}

export function releaseDate(value: string): string {
  return new Date(value).toLocaleDateString("id-ID", { dateStyle: "long", timeZone: "UTC" });
}

export function apkSize(bytes: number): string {
  return `${(bytes / 1024 / 1024).toLocaleString("id-ID", { maximumFractionDigits: 1 })} MB`;
}
