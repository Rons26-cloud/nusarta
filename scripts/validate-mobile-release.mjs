import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export function validateMobileRelease(tag, pubspec) {
  const semver = "(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)";
  if (!new RegExp(`^v${semver}$`).test(tag)) throw new Error("Release tag must be stable vX.Y.Z without leading zeroes.");
  const version = /^version:\s*([^\s#]+)\s*$/m.exec(pubspec)?.[1];
  if (!version || !new RegExp(`^${semver}\\+[1-9][0-9]*$`).test(version)) throw new Error("pubspec must declare X.Y.Z+build with a positive build number.");
  if (version.split("+")[0] !== tag.slice(1)) throw new Error("Release tag does not match pubspec version.");
  return version;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    validateMobileRelease(process.argv[2] ?? "", readFileSync(process.argv[3] ?? "pubspec.yaml", "utf8"));
    console.log("Stable tag and Flutter version match.");
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
