export const brand = {
  name: "NUSARTA",
  tagline: "Keuanganmu, Dalam Kendalimu.",
  description:
    "NUSARTA membantu kamu mencatat, memahami, dan mengendalikan keuangan pribadi dalam satu aplikasi yang sederhana dan aman.",
} as const;

export type Brand = typeof brand;

export const brandColors = {
  // Emerald greens
  deepest: "#041D16",
  dark: "#063B2C",
  primary: "#087A57",
  bright: "#0FA875",
  primaryDark: "#084C36",
  primaryLight: "#10A474",
  // Gold accents
  gold: "#D8A93D",
  goldlight: "#F0C75E",
  accent: "#C7A24A",
  accentLight: "#E3C878",
  // Cream/white backgrounds
  cream: "#F6F1E7",
  offwhite: "#FAF8F2",
  background: "#FFFFFF",
  backgroundOff: "#F7F8F8",
  // Text colors
  neutral: "#5A6B66",
  ink: "#14221D",
  textdark: "#14221D",
} as const;

export type BrandColors = typeof brandColors;
