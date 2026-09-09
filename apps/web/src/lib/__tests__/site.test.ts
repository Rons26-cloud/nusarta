import { afterEach, describe, expect, it, vi } from "vitest";
import { canonicalMetadata, releaseDownloadUrl, siteUrl } from "../site";
import robots from "../../app/robots";
import sitemap from "../../app/sitemap";

afterEach(() => vi.unstubAllEnvs());

describe("public deployment URLs", () => {
  it("does not invent a download or publish localhost SEO when unconfigured", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "");
    vi.stubEnv("NEXT_PUBLIC_DOWNLOAD_URL", "");
    expect(siteUrl()).toBe("");
    expect(canonicalMetadata("/download")).toBeUndefined();
    expect(sitemap()).toEqual([]);
    expect(robots().sitemap).toBeUndefined();
    expect(releaseDownloadUrl()).toBeNull();
  });

  it("uses the exact external APK URL and the configured site origin", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://example.org/");
    vi.stubEnv("NEXT_PUBLIC_DOWNLOAD_URL", "https://files.example.org/releases/NUSARTA.apk");
    expect(canonicalMetadata("/download")).toEqual({ canonical: "https://example.org/download" });
    expect(robots().sitemap).toBe("https://example.org/sitemap.xml");
    expect(sitemap()[0].url).toBe("https://example.org");
    expect(releaseDownloadUrl()).toBe("https://files.example.org/releases/NUSARTA.apk");
  });

  it.each(["javascript:alert(1)", "http://localhost:3000", "https://localhost", "https://user:password@example.org", "invalid"])("rejects an unsafe public URL", (value) => {
    vi.stubEnv("NEXT_PUBLIC_DOWNLOAD_URL", value);
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", value);
    expect(releaseDownloadUrl()).toBeNull();
    expect(siteUrl()).toBe("");
  });
});
