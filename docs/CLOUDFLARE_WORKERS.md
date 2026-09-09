# Cloudflare Workers deployment

STATUS: READY TO DEPLOY — build and local preview validated on 9 September 2026.
This is technical deployment readiness; see the dependency support limitations below.

The web application remains Next.js 14.2.35. Build tooling is pinned to
`@opennextjs/cloudflare` 1.14.8 and Wrangler 4.130.0. The adapter explicitly
supports Next.js ^14.2.35; its Wrangler peer requirement is ^4.53.0.
Use Node.js 22.23.2 (also recorded in `.node-version`) and npm with the root lockfile.

## GitHub integration

- Repository: `Rons26-cloud/nusarta`
- Production branch: `main`
- Root directory: `/` (repository root)
- Build command: `npm run build:worker`
- Deploy command: `npm run deploy:worker`
- Protect with Cloudflare Access: off for the public website.
- Non-production branch builds: off until a separate preview deployment workflow is configured.

Cloudflare installs dependencies from the root `package-lock.json`. Workspace
scripts execute inside `apps/web`, where OpenNext and Wrangler read
`open-next.config.ts` and `wrangler.jsonc`. The deploy command consumes the existing
build; it does not replace the build step. Do not run it locally for this setup.
No account ID, domain, bucket, or token is embedded in the configuration.

## Public build variables

Set these in the Cloudflare **build** environment before building, then rebuild
when changing them. They are public values, not secrets.

- `NEXT_PUBLIC_SITE_URL`: actual HTTPS website origin, including the assigned
  workers.dev origin if no custom domain exists yet. With no value, canonical
  and sitemap URLs are omitted rather than pointing to localhost.
- `NEXT_PUBLIC_DOWNLOAD_URL`: complete HTTPS URL of the verified APK in external
  storage. With no value, the existing unavailable download state is displayed.
- `NEXT_PUBLIC_CONTACT_EMAIL`: optional public support email.
- `NEXT_PUBLIC_PLAY_STORE_URL`: optional public Play Store listing URL.

None is required to compile. SITE_URL is required for complete production SEO;
DOWNLOAD_URL is required to enable the APK download. No Supabase credentials are
used by the website. NEXT_PUBLIC_APP_PORTAL_URL is not used.

## APK release lifecycle

Web builds consume tracked `packages/config/src/apk-metadata.ts`; they do not
read or generate APK binaries. Its current metadata was verified against the real
local `apps/web/public/downloads/NUSARTA.apk` (61,699,692 bytes):

`1ccb437ba11a8e893feecb496c2499206270040c8cf8d7eb24978899d554b1c7`

The source path is documented in `apps/web/public/downloads/README.md`.
Checksum verification establishes artifact identity, not production signing status.
Before publishing an APK, independently complete the existing release/signing checklist.

For every actual release:

1. Place the real, approved APK at the local release path; never commit it.
2. Run `npm run release:metadata`, then `npm run release:verify`.
   Verification fails on a missing binary, size mismatch, or checksum mismatch.
3. Review and commit the accurate metadata with the release details.
4. Upload the same verified binary to the chosen external/object storage.
5. Set its complete HTTPS URL as NEXT_PUBLIC_DOWNLOAD_URL and rebuild the Worker.
   The storage response must serve the correct MIME type and attachment filename.

APK files exceed Workers Static Asset limits. The Worker build removes only
generated APK copies from `.open-next/assets`; the original local file remains.
`.assetsignore` also excludes APKs from uploads. No R2 bucket is provisioned by
this repository, and no APK hosting is assumed to exist.

## Validation

From a clean repository root:

```sh
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run build:worker
npm run preview:worker
```

OpenNext produces `apps/web/.open-next/worker.js` and
`apps/web/.open-next/assets`. Local preview runs workerd without a deployment.
Check `/`, `/download`, `/robots.txt`, and `/sitemap.xml`, including the configured
and unconfigured URL states. Use Linux/WSL for build verification; native Windows
support in this adapter is limited. The ordinary `npm run build` remains available.

Validation completed in an isolated Ubuntu 24.04 checkout with Node 22.23.2 and
npm 10.9.8, using only prospective Git files (no APK, env files, node_modules,
or prior build output copied from the workstation): npm ci, lint, typecheck,
23 tests, ordinary Next.js build, and OpenNext build all passed. Worker entry
and assets were checked directly. Local workerd preview returned HTTP 200 on
the four routes above. Browser checks on `/` and `/download` loaded content,
CSS, fonts, and navigation with no browser errors. A second build with temporary
test-only public URLs verified the actual external download anchors and SEO
responses; those fixture values are not repository or deployment configuration.
APK size/checksum verification against the real local binary also passed.

No Cloudflare deployment or credential creation was performed during validation.

The site has no ISR, Server Actions, or on-demand revalidation; the standard
adapter configuration needs no cache bucket for the current application.
Dependency updates require a separate compatibility/security review; do not use
`npm audit fix --force` or change Next.js automatically.

## Dependency support limitations

Next.js 14 is retained by explicit project requirement. This does not imply
that its dependency audit is clean or that it is a currently supported framework
release. The adapter advisory GHSA-c7mq-gh6q-6q7c applies to versions <1.17.1;
the advisory documents automatic platform-level mitigation on Cloudflare Workers.
Adapter 1.17.1 and later checked releases no longer support Next.js 14 as a peer.
The platform mitigation does not remove the npm advisory or address unrelated
Next.js/transitive dependency advisories. Review those separately before treating
the deployment as security-approved production software.
