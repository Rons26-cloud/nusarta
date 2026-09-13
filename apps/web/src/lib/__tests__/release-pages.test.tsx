import type { ReactNode } from "react";
import { render, screen, within, cleanup } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { getGithubReleaseCatalog, getGithubTestRelease, normalizeReleases } from "../github-releases";
import { releaseFixture } from "./release-fixtures";
import DownloadPage from "@/app/download/page";
import ReleasesPage from "@/app/releases/page";

vi.mock("@/lib/github-releases", async (original) => ({...await original<typeof import("../github-releases")>(), getGithubReleaseCatalog: vi.fn(), getGithubTestRelease: vi.fn().mockResolvedValue(null)}));
vi.mock("@/components/Reveal", () => ({Reveal: ({children}: {children: ReactNode}) => <div>{children}</div>}));
vi.mock("@/components/PhoneMockup", () => ({PhoneMockup: () => <div />}));
afterEach(() => { cleanup(); vi.mocked(getGithubTestRelease).mockResolvedValue(null); });

describe("release pages", () => {
  it("renders current GitHub metadata and previous releases with exact links", async () => {
    const releases = normalizeReleases([releaseFixture("v1.0.3"), releaseFixture("v1.0.2"), releaseFixture("v1.0.1")]);
    vi.mocked(getGithubReleaseCatalog).mockResolvedValue({status: "ready", releases});
    render(await DownloadPage());
    expect(screen.getByText("Versi 1.0.3")).toBeInTheDocument();
    expect(screen.getByText("50 MB")).toBeInTheDocument();
    expect(screen.getAllByText("9 September 2026").length).toBeGreaterThan(0);
    expect(screen.getByRole("img", {name: "Logo resmi NUSARTA"})).toHaveAttribute("src", expect.stringContaining("nusarta02.png"));
    expect(screen.getByRole("link", {name: "Download NUSARTA APK"})).toHaveAttribute("href", releases[0].apkUrl);
    const history = screen.getByRole("region", {name: "Versi Lainnya"});
    expect(within(history).getByRole("link", {name: "Download APK v1.0.2"})).toHaveAttribute("href", releases[1].apkUrl);
    expect(within(history).queryByText("NUSARTA v1.0.3")).not.toBeInTheDocument();
    expect(within(history).getAllByRole("article")).toHaveLength(2);
  });
  it("renders the same full history and checksums on releases", async () => {
    const releases = normalizeReleases([releaseFixture("v1.0.3"), releaseFixture("v1.0.2")]);
    vi.mocked(getGithubReleaseCatalog).mockResolvedValue({status: "ready", releases});
    render(await ReleasesPage());
    expect(screen.getAllByRole("article")).toHaveLength(2);
    expect(screen.getAllByText("Versi terkini")).toHaveLength(1);
    expect(screen.getAllByText("a".repeat(64))).toHaveLength(2);
    expect(screen.getByRole("link", {name: "Download APK v1.0.2"})).toHaveAttribute("href", releases[1].apkUrl);
  });
  it("uses the exact external device-test APK URL", async () => {
    vi.mocked(getGithubReleaseCatalog).mockResolvedValue({status: "ready", releases: []});
    vi.mocked(getGithubTestRelease).mockResolvedValue({
      tag: "test-v1.0.3", version: "v1.0.3", apkName: "NUSARTA-TEST-v1.0.3.apk",
      title: "NUSARTA v1.0.1 Build 2 — Device Test", publishedAt: "2026-09-10T00:00:00Z",
      apkUrl: "https://github.com/Rons26-cloud/nusarta/releases/download/test-v1.0.3/NUSARTA-TEST-v1.0.3.apk", apkSize: 168525347,
    });
    render(await DownloadPage());
    const button = screen.getByRole("link", {name: "Download APK Pengujian"});
    expect(button).toHaveAttribute("href", "https://github.com/Rons26-cloud/nusarta/releases/download/test-v1.0.3/NUSARTA-TEST-v1.0.3.apk");
    expect(screen.getByRole("heading", {name: "v1.0.3"})).toBeInTheDocument();
    expect(button).not.toHaveAttribute("href", "/");
    expect(button).toHaveAttribute("rel", "noopener noreferrer");
  });
  it.each(["ready", "unavailable"] as const)("has safe %s state with no invented APK links", async (status) => {
    vi.stubEnv("NEXT_PUBLIC_DOWNLOAD_URL", "/downloads/NUSARTA.apk");
    vi.mocked(getGithubReleaseCatalog).mockResolvedValue({status, releases: []});
    const {container} = render(await DownloadPage());
    expect(screen.getByRole("button", {name: "Download APK Pengujian"})).toBeDisabled();
    expect(screen.getByRole("status")).toHaveTextContent(status === "unavailable" ? "belum dapat diperbarui" : "Belum ada rilis stabil");
    expect(container.querySelector('a[href$="/NUSARTA.apk"]')).toBeNull();
    expect(screen.queryByText("Versi 1.0.0")).not.toBeInTheDocument();
    vi.unstubAllEnvs();
  });
  it("renders safely with invalid release input filtered out", async () => {
    vi.mocked(getGithubReleaseCatalog).mockResolvedValue({status: "ready", releases: normalizeReleases([null, {}, releaseFixture("v1.0.0", {body: {bad: true}, name: []})])});
    render(await ReleasesPage());
    expect(screen.getByText("Belum ada rilis stabil dengan APK yang tersedia.")).toBeInTheDocument();
  });
});
