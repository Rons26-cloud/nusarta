import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createHash } from "node:crypto";
import { resolve } from "node:path";
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
describe("public APK integrity", () => {
  it("matches the published size and SHA-256", async () => {
    const file = resolve(process.cwd(), "public/downloads/NUSARTA.apk");
    const { size } = await stat(file);
    expect(size).toBeGreaterThan(0);
    expect(size).toBe(apkMetadata.sizeBytes);
    const hash = createHash("sha256");
    for await (const chunk of createReadStream(file)) hash.update(chunk);
    expect(hash.digest("hex")).toBe(currentRelease.checksumSha256);
  });
});
