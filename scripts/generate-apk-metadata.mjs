import { createReadStream } from "node:fs";
import { stat, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";

const apk = new URL("../apps/web/public/downloads/NUSARTA.apk", import.meta.url);
const output = new URL("../packages/config/src/apk-metadata.ts", import.meta.url);
const { size } = await stat(apk);
if (size === 0) throw new Error("NUSARTA.apk kosong.");

const hash = createHash("sha256");
for await (const chunk of createReadStream(apk)) hash.update(chunk);

const metadata = {
  fileName: "NUSARTA.apk",
  sizeBytes: size,
  sizeLabel: (size / 1_000_000).toFixed(2) + " MB",
  sha256: hash.digest("hex"),
};
await writeFile(output, "export const apkMetadata = " + JSON.stringify(metadata, null, 2) + " as const;\n");
