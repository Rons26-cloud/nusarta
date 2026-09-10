export interface NavItem {
  label: string;
  href: string;
}

export const siteConfig: {
  name: string;
  tagline: string;
  /** Set to your real public origin when available. Keep empty (no fake domain). */
  url: string;
  description: string;
} = {
  name: "NUSARTA",
  tagline: "Keuanganmu, Dalam Kendalimu.",
  url: "",
  description:
    "Aplikasi pengelola keuangan pribadi untuk mencatat pemasukan, pengeluaran, budget, saldo, dan tujuan keuangan dengan mudah.",
};

export const navItems: NavItem[] = [
  { label: "Beranda", href: "/" },
  { label: "Fitur", href: "/features" },
  { label: "Keamanan", href: "/security" },
  { label: "Community", href: "/community" },
  { label: "Download", href: "/download" },
  { label: "Tentang", href: "/about" },
];

export const footerNav = {
  product: [
    { label: "Fitur", href: "/features" },
    { label: "Keamanan", href: "/security" },
    { label: "Download", href: "/download" },
    { label: "Community", href: "/community" },
    { label: "Roadmap", href: "/roadmap" },
  ],
  company: [
    { label: "Tentang", href: "/about" },
    { label: "Changelog", href: "/changelog" },
    { label: "Releases", href: "/releases" },
  ],
  support: [
    { label: "FAQ", href: "/faq" },
    { label: "Cara Kerja", href: "/how-it-works" },
    { label: "Kontak", href: "/contact" },
  ],
  legal: [
    { label: "Privasi", href: "/privacy" },
    { label: "Syarat", href: "/terms" },
  ],
};

export const socialLinks: { label: string; href: string }[] = [];
