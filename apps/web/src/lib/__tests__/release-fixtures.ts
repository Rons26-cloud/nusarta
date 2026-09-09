export function releaseFixture(tag = "v1.0.2", overrides: Record<string, unknown> = {}) {
  return {
    tag_name: tag, draft: false, prerelease: false,
    name: `NUSARTA ${tag}`, body: "- Perbaikan stabilitas\n- Pembaruan fitur",
    published_at: "2026-09-09T10:00:00Z",
    assets: [{ name: "NUSARTA.apk", state: "uploaded", size: 52428800,
      browser_download_url: `https://github.com/Rons26-cloud/nusarta/releases/download/${encodeURIComponent(tag)}/NUSARTA.apk`,
      digest: `sha256:${"a".repeat(64)}` }],
    ...overrides,
  };
}
