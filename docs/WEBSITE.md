# Website — Environment & Notes

## Environment variables (public only)

`apps/web/.env.example` → salin sebagai `.env.local`.

| Variabel                  | Keterangan                                            |
| ------------------------- | ----------------------------------------------------- |
| `NEXT_PUBLIC_SITE_URL`    | Origin publik (mis. `https://www.nusarta.com`). Biarkan kosong selama domain belum final. |
| `NEXT_PUBLIC_DOWNLOAD_URL`| Base URL unduhan APK. Default: site URL (path `/downloads/...`). |
| `NEXT_PUBLIC_CONTACT_EMAIL`| Email yang dipakai halaman kontak.                    |
| `NEXT_PUBLIC_PLAY_STORE_URL`| URL Play Store. Hanya dirender jika terisi (mencegah badge palsu). |
| `NEXT_PUBLIC_APP_PORTAL_URL`| Cadangan portal akun masa depan.                     |

> Dilarang menaruh `SUPABASE_SERVICE_ROLE_KEY`, password DB, atau signing
> secret dalam env publik ini.

## Data terpusat

- `packages/config/src/release.ts` — metadata rilis.
- `apps/web/src/lib/data.ts` — feature, FAQ, roadmap, changelog.

## Versi & rilis

Download page membaca `packages/config`. Checksum SHA-256 dirender hanya
jika terisi. Changelog di `lib/data.ts` dan versi rilis harus konsisten.

## SEO

- Metadata per halaman (title, description, canonical).
- `robots.ts`, `sitemap.ts` otomatis (membaca `NEXT_PUBLIC_SITE_URL`).
- Structured data: Organization, SoftwareApplication (layout) dan
  FAQPage (halaman /faq).
- Hanya render structured data untuk konten yang benar-benar ada.

## Rute

`/` `/features` `/security` `/how-it-works` `/download` `/roadmap`
`/changelog` `/faq` `/about` `/contact` `/privacy` `/terms` + `/404`.