import type { Metadata } from "next";
import { Mail, MessagesSquare, FileQuestion } from "lucide-react";
import Link from "next/link";
import { PageHero } from "@/components/PageHero";
import { Reveal } from "@/components/Reveal";
import { ContactForm } from "@/components/ContactForm";
import { supportMethods, contactTopics } from "@/lib/data";
import { publicEmail } from "@/lib/site";

export const metadata: Metadata = {
  title: "Contact",
  description:
    "Hubungi tim NUSARTA untuk pertanyaan seputar akun, masalah aplikasi, keamanan, dan masukan.",
  alternates: { canonical: "/contact" },
};

export default function ContactPage() {
  return (
    <>
      <PageHero
        eyebrow="Bantuan & Kontak"
        title="Kami siap membantu"
        description={
          <p>
            Punya pertanyaan tentang NUSARTA? Hubungi kami melalui formulir
            berikut. Tim kami membalas melalui email.
          </p>
        }
      />

      <section className="py-16 lg:py-24">
        <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-10 lg:grid-cols-[1.4fr_1fr]">
            <Reveal>
              <div
              id="formulir-kontak"
              className="rounded-3xl border border-border bg-card p-5 sm:p-8 shadow-sm"
            >
                <h2 className="font-semibold text-foreground">
                  Kirim pesan
                </h2>
                <p className="mt-1 text-sm text-muted-foreground">
                  Biasanya kami merespons dalam beberapa hari kerja.
                </p>
                <div className="mt-6">
                  <ContactForm />
                </div>
              </div>
              <p className="mt-4 text-xs leading-relaxed text-muted-foreground">
                {publicEmail()
                  ? `Formulir ini membuka aplikasi email kamu (${publicEmail()}) dan belum terhubung ke sistem tiket produksi.`
                  : "Formulir ini membuka aplikasi email kamu ke alamat dukungan resmi (saat tersedia)."}
                {" "}Jangan sertakan PIN, kata sandi, atau informasi rekening
                dalam pesan.
              </p>
            </Reveal>

            <div className="space-y-6">
              <Reveal delay={0.1}>
                <div className="rounded-2xl border border-border bg-card p-6">
                  <h2 className="flex items-center gap-2 font-semibold text-foreground">
                    <MessagesSquare className="h-5 w-5 text-brand" />
                    Topik dukungan
                  </h2>
                  <div className="mt-4 flex flex-wrap gap-2">
                    {contactTopics.map((topic) => (
                      <span
                        key={topic}
                        className="rounded-lg border border-border px-3 py-1.5 text-xs text-muted-foreground"
                      >
                        {topic}
                      </span>
                    ))}
                  </div>
                </div>
              </Reveal>

              {supportMethods.map((method, i) => {
                const Icon = method.icon;
                return (
                  <Reveal key={method.title} delay={0.15 + i * 0.05}>
                    <Link
                      href={method.href}
                      className="block rounded-2xl border border-border bg-card p-6 transition-colors hover:border-nusa-primary/30"
                    >
                      <div className="flex items-start gap-4">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-nusa-primary/10 text-brand">
                          <Icon aria-hidden="true" className="h-5 w-5" />
                        </div>
                        <div>
                          <h3 className="font-semibold text-foreground">
                            {method.title}
                          </h3>
                          <p className="mt-1 text-sm text-muted-foreground">
                            {method.description}
                          </p>
                          <span className="mt-2 inline-flex items-center gap-1 text-sm font-semibold text-brand">
                            {method.label}
                          </span>
                        </div>
                      </div>
                    </Link>
                  </Reveal>
                );
              })}

              {supportMethods.length === 0 && (
                <div className="rounded-2xl border border-border bg-card p-6">
                  <div className="flex items-start gap-4">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-nusa-primary/10 text-brand">
                      <Mail aria-hidden="true" className="h-5 w-5" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-foreground">
                        Email dukungan
                      </h3>
                      <p className="mt-1 text-sm text-muted-foreground">
                        {publicEmail()
                          ? `Kirim pesan ke ${publicEmail()}.`
                          : "Alamat email resmi akan diumumkan sebelum rilis publik."}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              <Reveal delay={0.3}>
                <div className="rounded-2xl border border-border bg-card p-6">
                  <div className="flex items-start gap-4">
                    <FileQuestion aria-hidden="true" className="mt-1 h-5 w-5 shrink-0 text-accent-foreground" />
                    <div>
                      <h3 className="font-semibold text-foreground">
                        Butuh jawaban cepat?
                      </h3>
                      <p className="mt-1 text-sm text-muted-foreground">
                        Cek FAQ untuk menjawab pertanyaan umum.
                      </p>
                      <Link
                        href="/faq"
                        className="mt-2 inline-flex text-sm font-semibold text-brand hover:underline"
                      >
                        Buka FAQ
                      </Link>
                    </div>
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}