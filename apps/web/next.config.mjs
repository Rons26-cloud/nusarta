import { PHASE_DEVELOPMENT_SERVER } from "next/constants.js";

/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    "@nusarta/config",
    "@nusarta/ui",
    "@nusarta/utils",
    "@nusarta/types",
  ],
  async headers() {
    return [{
      source: "/downloads/NUSARTA.apk",
      headers: [
        { key: "Content-Type", value: "application/vnd.android.package-archive" },
        { key: "Content-Disposition", value: 'attachment; filename="NUSARTA.apk"' },
        { key: "Cache-Control", value: "public, max-age=0, must-revalidate" },
      ],
    }];
  },
  images: {
    remotePatterns: [],
    unoptimized: true,
  },
};

export default (phase) => ({
  ...nextConfig,
  // Keep development assets intact while a production build runs.
  distDir: phase === PHASE_DEVELOPMENT_SERVER ? ".next-dev" : ".next",
});