import { readdir, stat, unlink } from "node:fs/promises";
import { resolve, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const output = fileURLToPath(new URL("../apps/web/.open-next/", import.meta.url));
const assets = resolve(output, "assets");
await stat(resolve(output, "worker.js"));
// Only generated copies are removed; the release APK source is preserved.
for (const entry of await readdir(assets, { recursive: true, withFileTypes: true })) {
  if (!entry.isFile()) continue;
  const file = resolve(entry.parentPath ?? entry.path, entry.name);
  const within = relative(assets, file);
  if (within === ".." || within.startsWith(`..${sep}`) || resolve(assets, within) !== file) {
    throw new Error("Asset path escapes the generated output directory.");
  }
  if (/\.apk$/i.test(entry.name)) {
    await unlink(file);
    continue;
  }
  if (/^\.env(?:\.|$)|^\.dev\.vars|\.(?:pem|key|jks|keystore)$/i.test(entry.name)) {
    throw new Error("Credential-like file found in Worker assets.");
  }
  if ((await stat(file)).size > 25 * 1024 * 1024) {
    throw new Error(`Worker asset exceeds 25 MiB: ${within}`);
  }
}
console.log("Worker entry and assets verified; APK binaries excluded.");
