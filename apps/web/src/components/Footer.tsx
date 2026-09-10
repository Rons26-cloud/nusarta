import { footerNav, socialLinks } from "@nusarta/config";
import Image from "next/image";
import Link from "next/link";

function FooterColumn({ title, links }: { title: string; links: { label: string; href: string }[] }) {
  return (
    <div className="min-w-0">
      <h3 className="text-sm font-semibold text-foreground">{title}</h3>
      <ul className="mt-3">
        {links.map((link) => (
          <li key={link.href}>
            {link.href.startsWith("https://") ? <a href={link.href} target="_blank" rel="noopener noreferrer" className="inline-flex min-h-11 items-center text-sm text-muted-foreground transition-colors hover:text-brand">{link.label}</a> : <Link href={link.href} className="inline-flex min-h-11 items-center text-sm text-muted-foreground transition-colors hover:text-brand">{link.label}</Link>}
          </li>
        ))}
      </ul>
    </div>
  );
}

export function Footer() {
  return (
    <footer className="border-t border-border bg-muted">
      <div className="mx-auto w-full max-w-7xl px-4 py-14 sm:px-6 lg:px-8 lg:py-16">
        <div className="grid grid-cols-2 gap-x-6 gap-y-8 md:grid-cols-3 xl:grid-cols-[1.5fr_repeat(5,minmax(0,1fr))] lg:gap-8">
          <div className="col-span-2 min-w-0 lg:col-span-1">
            <Link href="/" aria-label="NUSARTA beranda" className="inline-flex min-h-11 items-center gap-2">
              <Image src="/nusarta02.png" width={40} height={40} alt="" />
              <span aria-hidden="true" className="text-xl font-bold tracking-tight text-foreground">NUS<span className="text-accent-foreground">A</span>RT<span className="text-accent-foreground">A</span></span>
            </Link>
            <p className="mt-3 max-w-xs text-sm leading-relaxed text-muted-foreground">Keuanganmu, Dalam Kendalimu.</p>
            {socialLinks.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-2">
                {socialLinks.map((link) => (
                  <Link key={link.href} href={link.href} className="inline-flex min-h-11 items-center rounded-lg border border-border px-3 text-sm text-brand" aria-label={link.label}>{link.label}</Link>
                ))}
              </div>
            )}
          </div>
          <FooterColumn title="Produk" links={footerNav.product} />
          <FooterColumn title="Perusahaan" links={footerNav.company} />
          <FooterColumn title="Bantuan" links={footerNav.support} />
          <FooterColumn title="Legal" links={footerNav.legal} />
          <FooterColumn title="Developer" links={[{ label: "NIAGANTARA", href: "https://niagantara-web.pages.dev/" }, { label: "Xyrons Portfolio", href: "https://my-portfolioo.pages.dev/" }, { label: "Xyrons Hub", href: "https://www.xyronhub.xyz/" }]} />
        </div>
        <div className="mt-10 grid gap-3 border-t border-border pt-6 text-xs leading-relaxed text-muted-foreground lg:grid-cols-2">
          <p>© {new Date().getFullYear()} NUSARTA. Dari Nusantara, Untuk Masa Depan yang Lebih Baik.</p>
          <p className="lg:text-right">NUSARTA bukan bank dan tidak menyimpan uang pengguna.</p>
        </div>
      </div>
    </footer>
  );
}
