import type { Metadata } from "next";
import Link from "next/link";
import { Compass } from "lucide-react";

export const metadata: Metadata = {
  title: "Halaman Tidak Ditemukan",
};

export default function NotFound() {
  return (
    <section className="flex min-h-[60vh] items-center justify-center py-24">
      <div className="mx-auto max-w-md px-6 text-center">
        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-nusa-primary/10 text-brand">
          <Compass aria-hidden="true" className="h-8 w-8" />
        </div>
        <h1 className="mt-6 font-display text-4xl font-extrabold text-foreground">
          404
        </h1>
        <p className="mt-3 text-muted-foreground">
          Halaman yang kamu cari tidak ditemukan atau sudah dipindahkan.
        </p>
        <Link
          href="/"
          className="mt-8 inline-flex items-center justify-center rounded-xl bg-nusa-primary px-6 py-3 font-semibold text-on-brand transition-transform hover:-translate-y-0.5"
        >
          Kembali ke beranda
        </Link>
      </div>
    </section>
  );
}