import { resolve } from "node:path";
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { validateMobileRelease } from "../../../../../scripts/validate-mobile-release.mjs";

describe("mobile release workflow", () => {
  it("accepts a stable tag matching pubspec", () => expect(validateMobileRelease("v1.0.0", "version: 1.0.0+1\n")).toBe("1.0.0+1"));
  it.each(["v01.0.0", "v1.0.0-beta", "v1.0.0+1", "1.0.0", "v2.0.0"])("rejects mismatched or invalid tag %s", tag => expect(() => validateMobileRelease(tag, "version: 1.0.0+1\n")).toThrow());
  it("requires a positive build number", () => expect(() => validateMobileRelease("v1.0.0", "version: 1.0.0+0\n")).toThrow());
  it("requires production signing and newline-separated release assets", () => {
    const workflow = readFileSync(resolve("../../.github/workflows/mobile-release.yml"), "utf8").replace(/\r\n/g, "\n");
    for (const name of ["ANDROID_KEYSTORE_BASE64", "ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD"]) expect(workflow).toContain(`secrets.${name}`);
    expect(workflow).toContain("flutter build apk --release");
    expect(workflow).toContain("fail_on_unmatched_files: true");
    expect(workflow).toContain("files: |\n            apps/mobile/NUSARTA.apk\n            apps/mobile/SHA256SUMS.txt");
    expect(workflow).toContain("sha256sum --check SHA256SUMS.txt");
    const gradle = readFileSync(resolve("../mobile/android/app/build.gradle"), "utf8").replace(/\r\n/g, "\n");
    expect(gradle).toContain("signingConfig signingConfigs.release");
    expect(gradle).not.toContain("signingConfigs.debug");
  });
});
