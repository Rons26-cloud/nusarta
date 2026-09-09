export { siteConfig, navItems, footerNav, socialLinks } from "@nusarta/config";

export function siteUrl(): string {
  return (
    process.env.NEXT_PUBLIC_SITE_URL ??
    "http://localhost:3000"
  );
}

export function publicEmail(): string {
  return process.env.NEXT_PUBLIC_CONTACT_EMAIL ?? "";
}

export function playStoreUrl(): string | null {
  const url = process.env.NEXT_PUBLIC_PLAY_STORE_URL;
  return url && url.trim().length > 0 ? url : null;
}

export function downloadBaseUrl(): string {
  return (
    process.env.NEXT_PUBLIC_DOWNLOAD_URL ??
    (process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000")
  );
}