import type { MetadataRoute } from "next";
import { siteUrl } from "@/lib/site";

export default function robots(): MetadataRoute.Robots {
  const url = siteUrl();
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/api/", "/admin"],
    },
    ...(url ? { sitemap: `${url}/sitemap.xml` } : {}),
  };
}
