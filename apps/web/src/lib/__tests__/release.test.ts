import { apkMetadata } from "../../../../../packages/config/src/apk-metadata";
import { describe, expect, it } from "vitest";

import { currentRelease, getReleaseDownloadUrl } from "@nusarta/config";

describe("release metadata", () => {
  it("exposes a single source of truth", () => {
    expect(currentRelease.version).toBe("1.0.0");
    expect(currentRelease.buildNumber).toBe("1");
    expect(currentRelease.platform).toBe("android");
    expect(currentRelease.channel).toBe("stable");
    expect(currentRelease.downloadUrl).toBe("/downloads/NUSARTA.apk");
    expect(currentRelease.apkFileName).toBe("NUSARTA.apk");
  });

  it("builds a relative download url when no base is provided", () => {
    expect(getReleaseDownloadUrl()).toBe(
      `/downloads/${currentRelease.apkFileName}`,
    );
  });

  it("builds a full download url from a base", () => {
    expect(getReleaseDownloadUrl("https://www.nusarta.com")).toBe(
      `https://www.nusarta.com/downloads/${currentRelease.apkFileName}`,
    );
    expect(getReleaseDownloadUrl("https://www.nusarta.com/")).toBe(
      `https://www.nusarta.com/downloads/${currentRelease.apkFileName}`,
    );
  });
});
describe("tracked release metadata", () => {
  it("contains a positive size and SHA-256 for the release artifact", () => {
    expect(apkMetadata.sizeBytes).toBeGreaterThan(0);
    expect(apkMetadata.sha256).toMatch(/^[a-f0-9]{64}$/);
    expect(currentRelease.checksumSha256).toBe(apkMetadata.sha256);
    expect(currentRelease.fileSizeMb).toBe(apkMetadata.sizeLabel);
  });
});
