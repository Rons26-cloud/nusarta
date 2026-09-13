import { afterEach, describe, expect, it, vi } from "vitest";
import { getGithubTestRelease, normalizeTestReleases } from "../github-releases";

const release = (tag: string, date = "2026-09-11T00:00:00Z") => ({
  tag_name: tag, draft: false, prerelease: true, published_at: date,
  assets: [{ name: `NUSARTA-TEST-${tag.slice(5)}.apk`, state: "uploaded", size: 123,
    browser_download_url: `https://github.com/Rons26-cloud/nusarta/releases/download/${tag}/NUSARTA-TEST-${tag.slice(5)}.apk` }],
});
afterEach(() => vi.unstubAllGlobals());

describe("Android testing releases", () => {
  it("selects the latest published eligible APK and preserves legacy build suffixes", () => {
    const old = release("test-v1.0.1-build2", "2026-09-10T00:00:00Z");
    expect(normalizeTestReleases([old, {...release("test-v1.0.2"), assets: []}])[0].version).toBe("v1.0.1-build2");
    expect(normalizeTestReleases([old, release("test-v1.0.3")])[0]).toMatchObject({
      version: "v1.0.3", apkName: "NUSARTA-TEST-v1.0.3.apk",
    });
  });
  it("excludes production, drafts, wrong assets, invalid URLs and invalid dates", () => {
    const item = release("test-v1.0.2");
    expect(normalizeTestReleases([
      release("v1.0.2"), {...item, prerelease: false}, {...item, draft: true},
      {...item, published_at: "invalid"}, {...item, assets: [{...item.assets[0], name: "NUSARTA.apk"}]},
      {...item, assets: [{...item.assets[0], browser_download_url: "https://evil.example/test.apk"}]},
    ])).toEqual([]);
  });
  it("paginates and picks a newer eligible release from the next page without auth", async () => {
    const fetcher = vi.fn().mockResolvedValueOnce(Response.json([release("test-v1.0.2")], {headers: {link: 'ignored; rel="next"'}}))
      .mockResolvedValueOnce(Response.json([release("test-v1.0.3", "2026-09-12T00:00:00Z")]));
    vi.stubGlobal("fetch", fetcher);
    expect((await getGithubTestRelease())?.version).toBe("v1.0.3");
    expect(fetcher.mock.calls[1][0]).toBe("https://api.github.com/repos/Rons26-cloud/nusarta/releases?per_page=100&page=2&channel=testing-v1");
    expect(fetcher.mock.calls[0][1].headers).not.toHaveProperty("Authorization");
    expect(fetcher.mock.calls[0][1].cache).toBe("no-store");
  });
  it.each([403, 429, 500])("uses the verified testing release on HTTP %s", async (status) => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(null, {status})));
    expect((await getGithubTestRelease())?.apkUrl).toContain("test-v1.0.3/NUSARTA-TEST-v1.0.3.apk");
  });
  it("handles offline, malformed responses and releases without APKs", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValueOnce(new Error("offline"))
      .mockResolvedValueOnce(Response.json({message: "error"}))
      .mockResolvedValueOnce(Response.json([{...release("test-v1.0.2"), assets: []}])));
    expect((await getGithubTestRelease())?.apkUrl).toContain("test-v1.0.3/NUSARTA-TEST-v1.0.3.apk");
    expect((await getGithubTestRelease())?.apkUrl).toContain("test-v1.0.3/NUSARTA-TEST-v1.0.3.apk");
    expect((await getGithubTestRelease())?.apkUrl).toContain("test-v1.0.3/NUSARTA-TEST-v1.0.3.apk");
  });
});
