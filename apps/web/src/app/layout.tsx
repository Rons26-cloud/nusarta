import type { Metadata, Viewport } from "next";
import { Inter, Plus_Jakarta_Sans } from "next/font/google";
import { siteConfig } from "@/lib/site";
import { ThemeProvider } from "@/components/ThemeProvider";
import { Navbar } from "@/components/Navbar";
import { BackNavigation } from "@/components/BackNavigation";
import { Footer } from "@/components/Footer";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-plus-jakarta",
  display: "swap",
});

const url = siteConfig.url
  ? siteConfig.url.replace(/\/$/, "")
  : undefined;

const baseMetadata = {
  title: {
    default: "NUSARTA — Keuanganmu, Dalam Kendalimu",
    template: "%s — NUSARTA",
  },
  description: siteConfig.description,
  keywords: [
    "NUSARTA",
    "Nusa Arta",
    "NUSARTA finance",
    "NUSARTA keuangan",
    "aplikasi NUSARTA",
  ],
};

export const metadata: Metadata = {
  ...baseMetadata,
  metadataBase: url ? new URL(url) : undefined,
  alternates: url ? { canonical: url } : undefined,
  openGraph: {
    type: "website",
    siteName: "NUSARTA",
    title: "NUSARTA — Keuanganmu, Dalam Kendalimu",
    description: siteConfig.description,
    url: url,
    locale: "id_ID",
    images: [{ url: "/hero.png", alt: "NUSARTA - aplikasi keuangan pribadi" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "NUSARTA — Keuanganmu, Dalam Kendalimu",
    description: siteConfig.description,
    images: ["/hero.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
  applicationName: "NUSARTA",
  manifest: "/site.webmanifest",
  icons: {
    icon: [
      { url: "/favicon.ico?v=official-n", sizes: "16x16 32x32 48x48", type: "image/x-icon" },
      { url: "/favicon-16x16.png?v=official-n", sizes: "16x16", type: "image/png" },
      { url: "/favicon-32x32.png?v=official-n", sizes: "32x32", type: "image/png" },
      { url: "/favicon-48x48.png?v=official-n", sizes: "48x48", type: "image/png" },
    ],
    apple: [{ url: "/apple-touch-icon.png?v=official-n", sizes: "180x180", type: "image/png" }],
  },
};

const organizationJsonLd = {
  "@context": "https://schema.org",
  "@type": "Organization",
  name: "NUSARTA",
  slogan: "Keuanganmu, Dalam Kendalimu.",
  description: siteConfig.description,
  ...(url ? { url } : {}),
};

const softwareJsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "NUSARTA",
  applicationCategory: "FinanceApplication",
  operatingSystem: "Android",
  description: siteConfig.description,
  slogan: "Keuanganmu, Dalam Kendalimu.",
  ...(url ? { url } : {}),
};

const websiteJsonLd = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  name: "NUSARTA",
  alternateName: ["Nusa Arta", "NUSARTA personal finance"],
  ...(url ? { url } : {}),
  publisher: { "@id": url ? `${url}/#organization` : undefined },
};

const organizationWithIdentity = {
  ...organizationJsonLd,
  "@id": url ? `${url}/#organization` : undefined,
  logo: url ? `${url}/nusarta02.png` : "/nusarta02.png",
  sameAs: ["https://github.com/Rons26-cloud/nusarta"],
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#FBFAF6" },
    { media: "(prefers-color-scheme: dark)", color: "#041D16" },
  ],
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="id"
      className={`${inter.variable} ${plusJakarta.variable}`}
      suppressHydrationWarning
    >
      <body className="min-h-screen bg-background font-sans text-foreground">
        <ThemeProvider>
          <div className="flex min-h-screen flex-col">
            <script
              type="application/ld+json"
              dangerouslySetInnerHTML={{
                __html: JSON.stringify(organizationWithIdentity),
              }}
            />
            <script
              type="application/ld+json"
              dangerouslySetInnerHTML={{
                __html: JSON.stringify(softwareJsonLd),
              }}
            />
            <script
              type="application/ld+json"
              dangerouslySetInnerHTML={{
                __html: JSON.stringify(websiteJsonLd),
              }}
            />
            <Navbar />
            <main className="flex-1">
              <BackNavigation />
              {children}
            </main>
            <Footer />
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
