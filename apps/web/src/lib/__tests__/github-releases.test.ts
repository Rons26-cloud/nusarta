import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { normalizeReleases } from "../github-releases";
import { releaseFixture as release } from "./release-fixtures";

afterEach(() => { vi.unstubAllGlobals(); vi.useRealTimers(); });

describe("stable release catalog", () => {
  it("sorts semantic versions, not dates or lexical order", () => {
    expect(normalizeReleases([release("v1.0.9"), release("v2.0.0"), release("v1.0.10")]).map(x => x.version)).toEqual(["2.0.0", "1.0.10", "1.0.9"]);
  });
  it.each(["v01.0.0", "v1.00.0", "v1.0.0-beta.1", "v1.0", "v1.0.0 ", "not-a-version"])("rejects invalid/nonstable tag %s", (tag) => {
    expect(normalizeReleases([release(tag)])).toEqual([]);
  });
  it("excludes the confirmed broken v1.0.0 release", () => {
    expect(normalizeReleases([release("v1.0.0")])).toEqual([]);
  });
  it("accepts stable semver build metadata and compares large versions exactly", () => {
    expect(normalizeReleases([release("v9007199254740992.0.0"), release("v9007199254740993.0.0"), release("v1.0.0+build.2")]).map(x => x.version)).toEqual(["9007199254740993.0.0", "9007199254740992.0.0", "1.0.0+build.2"]);
  });
  it("ignores drafts, prereleases, unpublished releases and missing APKs", () => {
    expect(normalizeReleases([release("v5.0.0", {draft: true}), release("v4.0.0", {prerelease: true}), release("v3.0.0", {published_at: null}), release("v2.0.0", {assets: []}), release()]).map(x => x.version)).toEqual(["1.0.2"]);
  });
  it.each([
    {name: "other.apk"}, {state: "starter"}, {size: 0}, {size: -1}, {size: "100"},
    {browser_download_url: "javascript:alert(1)"},
    {browser_download_url: "https://evil.example/NUSARTA.apk"},
    {browser_download_url: "https://github.com/other/repo/releases/download/v1.0.0/NUSARTA.apk"},
    {browser_download_url: "https://github.com/Rons26-cloud/nusarta/releases/download/v2.0.0/NUSARTA.apk"},
    {browser_download_url: "https://github.com/Rons26-cloud/nusarta/releases/latest/download/NUSARTA.apk"},
  ])("rejects invalid APK metadata %j", (overrides) => {
    const item = release(); item.assets = [{...item.assets[0], ...overrides}] as typeof item.assets;
    expect(normalizeReleases([item])).toEqual([]);
  });
  it("keeps exact historical URLs and excludes latest from history", () => {
    const [latest, ...history] = normalizeReleases([release("v1.0.1"), release("v1.0.3"), release("v1.0.2")]);
    expect(latest.version).toBe("1.0.3");
    expect(history.map(x => x.version)).toEqual(["1.0.2", "1.0.1"]);
    expect(history[0].apkUrl).toBe("https://github.com/Rons26-cloud/nusarta/releases/download/v1.0.2/NUSARTA.apk");
  });
  it("handles empty and malformed data without throwing", () => {
    expect(normalizeReleases(null)).toEqual([]);
    expect(normalizeReleases([null, 2, {}, release("v2.0.0", {published_at: "invalid"}), release("v1.0.2", {name: {}, body: {}})])).toHaveLength(1);
    expect(normalizeReleases([])).toEqual([]);
  });
  it("uses only published checksum metadata and deduplicates tags", () => {
    const item = release();
    const result = normalizeReleases([item, item]);
    expect(result).toHaveLength(1);
    expect(result[0].sha256).toBe("a".repeat(64));
    expect(result[0].checksumUrl).toBeNull();
    const checksum = {name: "SHA256SUMS.txt", state: "uploaded", size: 78, browser_download_url: "https://github.com/Rons26-cloud/nusarta/releases/download/v1.0.2/SHA256SUMS.txt"};
    expect(normalizeReleases([{...item, assets: [...item.assets, checksum]}])[0].checksumUrl).toBe(checksum.browser_download_url);
  });
});

describe("GitHub fetch and bounded cache", () => {
  beforeEach(() => vi.resetModules());
  it("deduplicates requests and rolls the former latest into history after expiry", async () => {
    vi.useFakeTimers();
    const fetcher = vi.fn().mockResolvedValueOnce(Response.json([release("v1.0.3"), release("v1.0.2")])).mockResolvedValueOnce(Response.json([release("v1.0.4"), release("v1.0.3"), release("v1.0.2")]));
    vi.stubGlobal("fetch", fetcher);
    const {getGithubReleaseCatalog} = await import("../github-releases");
    const results = await Promise.all([getGithubReleaseCatalog(), getGithubReleaseCatalog()]);
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(results[0].releases[0].version).toBe("1.0.3");
    await vi.advanceTimersByTimeAsync(300001);
    const updated = await getGithubReleaseCatalog();
    expect(updated.releases.map(x => x.version)).toEqual(["1.0.4", "1.0.3", "1.0.2"]);
    expect(fetcher).toHaveBeenCalledTimes(2);
  });
  it("paginates without dropping older history", async () => {
    const fetcher = vi.fn().mockResolvedValueOnce(Response.json([release("v2.0.0")], {headers: {link: '<https://api.github.com/anything>; rel="next"'}})).mockResolvedValueOnce(Response.json([release()]));
    vi.stubGlobal("fetch", fetcher);
    const {getGithubReleaseCatalog} = await import("../github-releases");
    expect((await getGithubReleaseCatalog()).releases).toHaveLength(2);
    expect(fetcher.mock.calls[1][0]).toBe("https://api.github.com/repos/Rons26-cloud/nusarta/releases?per_page=100&page=2");
  });
  it.each(["network", "http", "json", "shape"])("returns unavailable safely on %s failure", async (kind) => {
    vi.stubGlobal("fetch", kind === "network" ? vi.fn().mockRejectedValue(new Error("offline")) : vi.fn().mockResolvedValue(kind === "http" ? new Response(null, {status: 503}) : kind === "json" ? new Response("bad json") : Response.json({message: "invalid"})));
    const {getGithubReleaseCatalog} = await import("../github-releases");
    expect(await getGithubReleaseCatalog()).toEqual({status: "unavailable", releases: []});
  });
  it("distinguishes an empty catalog from an API failure", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(Response.json([])));
    const {getGithubReleaseCatalog} = await import("../github-releases");
    expect(await getGithubReleaseCatalog()).toEqual({status: "ready", releases: []});
  });
  it("does not claim expired data is fresh during an outage and retries after 30s", async () => {
    vi.useFakeTimers();
    const fetcher = vi.fn().mockResolvedValueOnce(Response.json([release()])).mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce(Response.json([release("v1.0.1")]));
    vi.stubGlobal("fetch", fetcher);
    const {getGithubReleaseCatalog} = await import("../github-releases");
    await getGithubReleaseCatalog();
    await vi.advanceTimersByTimeAsync(300001);
    expect((await getGithubReleaseCatalog()).status).toBe("unavailable");
    await getGithubReleaseCatalog();
    expect(fetcher).toHaveBeenCalledTimes(2);
    await vi.advanceTimersByTimeAsync(30001);
    expect((await getGithubReleaseCatalog()).releases[0].version).toBe("1.0.1");
  });
  it("shares catalog through Cloudflare cache without extending its lifetime", async () => {
    const catalog = {status: "ready", releases: normalizeReleases([release()])};
    const match = vi.fn().mockResolvedValue(Response.json({expiresAt: Date.now()+2000, catalog}));
    vi.stubGlobal("caches", {default: {match, put: vi.fn()}});
    const fetcher = vi.fn(); vi.stubGlobal("fetch", fetcher);
    const {getGithubReleaseCatalog} = await import("../github-releases");
    expect(await getGithubReleaseCatalog()).toEqual(catalog);
    expect(fetcher).not.toHaveBeenCalled();
  });
  it("cache read/write errors do not break GitHub fetching", async () => {
    vi.stubGlobal("caches", {default: {match: vi.fn().mockRejectedValue(new Error()), put: vi.fn().mockRejectedValue(new Error())}});
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(Response.json([release()])));
    const {getGithubReleaseCatalog} = await import("../github-releases");
    expect((await getGithubReleaseCatalog()).status).toBe("ready");
  });
});
