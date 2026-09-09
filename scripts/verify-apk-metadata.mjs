import { createReadStream } from "node:fs";
import { readFile, stat } from "node:fs/promises";
import { createHash } from "node:crypto";
import assert from "node:assert/strict";

const file = new URL("../apps/web/public/downloads/NUSARTA.apk", import.meta.url);
const source = await readFile(new URL("../packages/config/src/apk-metadata.ts", import.meta.url), "utf8");
const metadata = JSON.parse(source.slice(source.indexOf("{"), source.lastIndexOf("}") + 1));
const { size } = await stat(file);
assert(size > 0, "Release APK must not be empty.");
assert.equal(size, metadata.sizeBytes, "APK size differs from release metadata.");
const hash = createHash("sha256");
for await (const chunk of createReadStream(file)) hash.update(chunk);
assert.equal(hash.digest("hex"), metadata.sha256, "APK checksum differs from release metadata.");
console.log("Release APK size and SHA-256 match the tracked metadata.");
