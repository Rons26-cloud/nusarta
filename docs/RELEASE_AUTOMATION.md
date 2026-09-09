# Automatic Android release history

GitHub Releases in Rons26-cloud/nusarta is the canonical APK source. APKs stay
out of Git and Cloudflare static assets. /download and /releases share the
validated catalog in apps/web/src/lib/github-releases.ts.

## Selection and safety

Only explicitly non-draft, non-prerelease releases with stable semantic tags,
a valid published timestamp, and an exact uploaded NUSARTA.apk with positive
size are included. Asset URLs must belong to this repository and the same tag.
Versions sort by semantic precedence, not release date. The first is current;
all others form Versi Lainnya. API pagination preserves older releases.

All displayed size, date, notes and SHA-256 values come from the same GitHub
release. SHA-256 is shown when the API publishes its digest. If SHA256SUMS.txt
is uploaded, its exact asset is linked. Missing assets are omitted. Local
packages/config APK metadata and NEXT_PUBLIC_DOWNLOAD_URL are not fallbacks.

## Freshness on Next.js and OpenNext/Cloudflare

Both pages use force-dynamic rendering. Successful catalog snapshots expire
after 300 seconds. A Cloudflare Cache API entry shares snapshots within an edge
location; a bounded in-memory cache supports Node and cache failures. Concurrent
requests within an instance are deduplicated. No R2/KV binding, filesystem cache,
Next.js ISR bucket, release webhook, or per-release website edit is required.

Requests have a 10-second total timeout. Failures return an unavailable state
with no fabricated APK links; failure results are retried after 30 seconds.
Expired snapshots are not labelled current during an outage. A freshly published
release is discovered on the next page request after the current cache expires.
An already-open tab requires navigation/reload to show the new snapshot.

References:
- https://developers.cloudflare.com/workers/runtime-apis/cache/
- https://opennext.js.org/cloudflare/caching

## Future release workflow (not executed by this change)

1. Bump apps/mobile/pubspec.yaml to X.Y.Z+build with a positive, increasing build.
2. Review and push the matching stable vX.Y.Z tag only when release is approved.
3. GitHub Actions validates tag/version before building or restoring signing.
4. It checks formatting, analyzes (existing info-only lints are nonfatal), and
   runs tests. Warnings and errors still fail analysis.
5. It restores the existing production keystore, builds a release APK, creates
   NUSARTA.apk and SHA256SUMS.txt, verifies the checksum, and uploads both assets.
6. The website discovers the release after cache expiry. The existing mobile
   updater consumes the same repository, stable tags and exact APK filename.

Required existing GitHub Actions secrets (never store in source):
- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

Required GitHub repository variables, public client configuration only:
- SUPABASE_URL: https://ogdccbbwfktrvhnkorvt.supabase.co
- SUPABASE_ANON_KEY: the public anon or publishable key for this project

The workflow refuses a non-public key or incorrect project URL and never
creates a replacement signing key. Android's release guard remains mandatory;
there is no debug-signing fallback. Check signing-certificate continuity and
increasing Android versionCode before an actual release. No tag, production
release, APK upload, or deployment was performed during this implementation.

The existing ignored apps/web/public/downloads/NUSARTA.apk is a preserved legacy
local copy, not the production source. See that directory's README.
