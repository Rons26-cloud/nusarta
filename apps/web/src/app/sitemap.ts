import type { MetadataRoute } from "next";
import { siteUrl } from "@/lib/site";

export default function sitemap(): MetadataRoute.Sitemap {
  const url = siteUrl().replace(/\/$/, "");
  const routes = [
    "",
    "/features",
    "/security",
    "/how-it-works",
    "/download",
    "/roadmap",
    "/changelog",
    "/faq",
    "/about",
    "/contact",
    "/privacy",
    "/terms",
  ] as const;

  return routes.map((route) => ({
    url: `${url}${route}`,
    lastModified: new Date(),
    changeFrequency: route === "" ? "monthly" : "monthly",
    priority: route === "" ? 1 : 0.8,
  }));
}