import { afterEach, describe, expect, it, vi } from "vitest";
import { canonicalMetadata, releaseDownloadUrl, siteUrl } from "../site";
import robots from "../../app/robots";
import sitemap from "../../app/sitemap";

afterEach(() => vi.unstubAllEnvs());

describe("public deployment URLs", () => {
  it("uses the declared production origin when the build variable is absent", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "");
    vi.stubEnv("NEXT_PUBLIC_DOWNLOAD_URL", "");
    expect(siteUrl()).toBe("https://nusarta.nusarta-official.workers.dev");
    expect(canonicalMetadata("/")).toEqual({ canonical: "/" });
    expect(canonicalMetadata("/download")).toEqual({ canonical: "https://nusarta.nusarta-official.workers.dev/download" });
    expect(sitemap()[0].url).toBe("https://nusarta.nusarta-official.workers.dev");
    expect(robots().sitemap).toBe("https://nusarta.nusarta-official.workers.dev/sitemap.xml");
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
    expect(siteUrl()).toBe("https://nusarta.nusarta-official.workers.dev");
  });
});
