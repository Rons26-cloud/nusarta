import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

const dirname = fileURLToPath(new URL(".", import.meta.url));

export default defineConfig({
  plugins: [react()],
  esbuild: {
    jsx: "automatic",
    jsxImportSource: "react",
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./vitest.setup.ts"],
    exclude: ["node_modules", "**/.next/**", "**/.next-dev/**"],
  },
  resolve: {
    alias: {
      "@": `${dirname}src`,
      "@nusarta/config": `${dirname}../../packages/config/src/index.ts`,
      "@nusarta/ui": `${dirname}../../packages/ui/src/index.ts`,
      "@nusarta/utils": `${dirname}../../packages/utils/src/index.ts`,
      "@nusarta/types": `${dirname}../../packages/types/src/index.ts`,
    },
  },
});