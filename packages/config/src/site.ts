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
  { label: "Cara Kerja", href: "/how-it-works" },
  { label: "Roadmap", href: "/roadmap" },
  { label: "FAQ", href: "/faq" },
];

export const footerNav = {
  product: [
    { label: "Fitur", href: "/features" },
    { label: "Keamanan", href: "/security" },
    { label: "Download", href: "/download" },
    { label: "Roadmap", href: "/roadmap" },
  ],
  company: [
    { label: "Tentang", href: "/about" },
    { label: "Changelog", href: "/changelog" },
  ],
  support: [
    { label: "FAQ", href: "/faq" },
    { label: "Cara Kerja", href: "/how-it-works" },
    { label: "Komunitas", href: "/community" },
    { label: "Kontak", href: "/contact" },
  ],
  legal: [
    { label: "Privasi", href: "/privacy" },
    { label: "Syarat", href: "/terms" },
  ],
};

export const socialLinks: { label: string; href: string }[] = [];
