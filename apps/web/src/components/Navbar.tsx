"use client";

import { navItems } from "@nusarta/config";
import { cn } from "@nusarta/utils";
import { AnimatePresence, motion } from "framer-motion";
import { Menu, Moon, Sun, X } from "lucide-react";
import { useTheme } from "next-themes";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  return (
    <button
      aria-label="Ganti mode tampilan"
      aria-pressed={mounted && resolvedTheme === "dark"}
      disabled={!mounted}
      onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
      className="inline-flex h-11 w-11 items-center justify-center rounded-lg border border-border text-foreground transition-colors hover:bg-muted"
    >
      {mounted && resolvedTheme === "dark" ? (
        <Sun aria-hidden="true" className="h-4 w-4" />
      ) : (
        <Moon aria-hidden="true" className="h-4 w-4" />
      )}
    </button>
  );
}

export function Navbar() {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => setOpen(false), [pathname]);

  return (
    <header
      className="site-header sticky top-0 z-50 border-b border-border bg-background"
    >
      <nav
        className="mx-auto flex h-16 w-full sm:h-20 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8"
        aria-label="Navigasi utama"
      >
        <Link href="/" aria-label="NUSARTA beranda" className="group flex shrink-0 items-center gap-2 sm:gap-3">
          <div className="relative h-10 w-10 shrink-0 sm:h-12 sm:w-12">
            <Image
              src="/nusarta02.png"
              alt=""
              fill
              className="object-contain" sizes="(min-width: 640px) 48px, 40px"
            />
          </div>
          <span aria-hidden="true" className="whitespace-nowrap text-xl font-black tracking-tighter text-foreground sm:text-2xl">NUS<span className="text-accent-foreground">A</span>RT<span className="text-accent-foreground">A</span></span>
        </Link>

        <div className="hidden items-center gap-0 xl:gap-2 lg:flex">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "inline-flex min-h-11 items-center rounded-lg px-2 xl:px-4 py-2 text-sm font-medium transition-colors",
                pathname === item.href
                  ? "text-accent-foreground"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              {item.label}
            </Link>
          ))}
        </div>

        <div className="flex shrink-0 items-center gap-3 xl:gap-5">
          <ThemeToggle />
          <Link
            href="/download"
            className="hidden rounded-lg bg-nusa-gold px-4 xl:px-5 py-3 text-sm font-semibold text-nusa-deepest transition-colors hover:bg-nusa-goldlight lg:inline-flex"
          >
            Download App
          </Link>
          <button
            aria-label={open ? "Tutup menu" : "Buka menu"}
            aria-expanded={open}
            aria-controls="mobile-navigation"
            onClick={() => setOpen((v) => !v)}
            className="inline-flex h-11 w-11 items-center justify-center rounded-lg border border-border text-foreground lg:hidden"
          >
            {open ? <X aria-hidden="true" className="h-5 w-5" /> : <Menu aria-hidden="true" className="h-5 w-5" />}
          </button>
        </div>
      </nav>

      <AnimatePresence>
        {open && (
          <motion.div
            id="mobile-navigation"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden border-t border-border bg-background lg:hidden"
          >
            <div className="space-y-1 px-6 py-4">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "flex min-h-11 items-center rounded-lg px-3 py-2.5 text-sm font-medium",
                    pathname === item.href
                      ? "bg-nusa-primary/10 text-accent-foreground"
                      : "text-muted-foreground hover:text-foreground",
                  )}
                >
                  {item.label}
                </Link>
              ))}
              <Link
                href="/download"
                className="mt-2 block rounded-xl bg-nusa-gold px-4 py-3 text-center text-sm font-semibold text-nusa-ink"
              >
                Download App
              </Link>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
}