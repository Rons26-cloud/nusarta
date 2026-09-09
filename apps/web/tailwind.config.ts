import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./src/**/*.{ts,tsx}",
    "../../packages/ui/src/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        "background": "rgb(var(--background) / <alpha-value>)",
        "foreground": "rgb(var(--foreground) / <alpha-value>)",
        "card": "rgb(var(--card) / <alpha-value>)",
        "muted": "rgb(var(--muted) / <alpha-value>)",
        "muted-foreground": "rgb(var(--muted-foreground) / <alpha-value>)",
        "border": "rgb(var(--border) / <alpha-value>)",
        "brand": "rgb(var(--brand) / <alpha-value>)",
        "accent-foreground": "rgb(var(--accent-foreground) / <alpha-value>)",
        "on-brand": "rgb(var(--on-brand) / <alpha-value>)",
        "positive": "rgb(var(--positive) / <alpha-value>)",
        "negative": "rgb(var(--negative) / <alpha-value>)",
        nusa: {
          // Emerald greens
          deepest: "#031D16",
          dark: "#063B2C",
          primary: "#075C43",
          bright: "#0B8A63",
          primarydark: "#063B2C",
          primarylight: "#075C43",
          // Gold accents
          gold: "#D9A93B",
          goldlight: "#F1C75B",
          accent: "#D9A93B",
          accentlight: "#F1C75B",
          // Cream/white backgrounds
          cream: "#F6F0E5",
          offwhite: "#F6F0E5",
          background: "#FFFFFF",
          off: "#F7F8F8",
          // Text colors
          neutral: "#5A6B66",
          ink: "#031D16",
          textdark: "#031D16",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "ui-sans-serif", "system-ui", "sans-serif"],
        display: ["var(--font-plus-jakarta)", "var(--font-inter)", "ui-sans-serif"],
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-10px)" },
        },
        "float-delayed": {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
      },
      animation: {
        float: "float 5s ease-in-out infinite",
        "float-delayed": "float-delayed 5s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;