# Legacy local APK directory

The ignored NUSARTA.apk in this directory is a local legacy copy. It is not
tracked, is not used by /download or /releases, and is excluded from generated
Cloudflare Worker assets by scripts/finalize-worker.mjs. Do not copy or move APKs
here for production releases. The existing local copy is intentionally preserved.

Canonical production artifacts are GitHub Release assets:
https://github.com/Rons26-cloud/nusarta/releases

Publish stable vX.Y.Z tags through .github/workflows/mobile-release.yml. The
workflow attaches NUSARTA.apk and SHA256SUMS.txt. The website discovers current
and previous stable versions automatically; no website rebuild or metadata edit
is needed for a new release. Historical links use each exact release asset URL.

The old release:metadata / release:verify scripts and packages/config metadata
are legacy local-artifact helpers, not the website release catalog.
