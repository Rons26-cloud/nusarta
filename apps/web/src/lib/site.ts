import { siteConfig as brandSiteConfig } from "@nusarta/config";
export { navItems, footerNav, socialLinks } from "@nusarta/config";

const productionOrigin = "https://nusarta.nusarta-official.workers.dev";

function publicHttpsUrl(value: string | undefined): string | null {
  if (!value?.trim()) return null;
  const trimmed = value.trim();
  if (trimmed.startsWith("/") && !trimmed.startsWith("//")) {
    return trimmed;
  }
  try {
    const url = new URL(trimmed);
    if (url.protocol !== "https:" || url.username || url.password ||
        /^(localhost|127\.|\[::1\])/.test(url.hostname)) return null;
    return url.href;
  } catch {
    return null;
  }
}

export function siteUrl(): string {
  const url = publicHttpsUrl(process.env.NEXT_PUBLIC_SITE_URL);
  return url ? new URL(url).origin : productionOrigin;
}

export const siteConfig = { ...brandSiteConfig, url: siteUrl() };

export function canonicalMetadata(path: string) {
  const origin = siteUrl();
  return origin
    ? { canonical: path === "/" ? "/" : new URL(path, origin).href }
    : undefined;
}

export function releaseDownloadUrl(): string | null {
  return publicHttpsUrl(process.env.NEXT_PUBLIC_DOWNLOAD_URL);
}

export function publicEmail(): string {
  return process.env.NEXT_PUBLIC_CONTACT_EMAIL ?? "";
}

export function playStoreUrl(): string | null {
  const url = process.env.NEXT_PUBLIC_PLAY_STORE_URL;
  return url && url.trim().length > 0 ? url : null;
}
