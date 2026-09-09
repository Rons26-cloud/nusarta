"use client";

import { useState } from "react";
import { Mail, Send } from "lucide-react";
import { contactTopics } from "@/lib/data";
import { publicEmail } from "@/lib/site";

export function ContactForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [subject, setSubject] = useState(contactTopics[0]);
  const [message, setMessage] = useState("");
  const [sent, setSent] = useState(false);

  const valid =
    name.trim().length > 1 &&
    email.includes("@") &&
    message.trim().length > 5;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const to = publicEmail();
    if (!to) return;
    const body = encodeURIComponent(
      `Nama: ${name}\nEmail: ${email}\nTopik: ${subject}\n\n${message}`,
    );
    window.location.href = `mailto:${to}?subject=${encodeURIComponent(
      `[NUSARTA] ${subject}`,
    )}&body=${body}`;
    setSent(true);
  };

  const inputClass =
    "w-full rounded-xl border border-border bg-card px-4 py-3 text-base text-foreground outline-none transition-colors focus:border-nusa-primary    ";

  const supportEmail = publicEmail();

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="name" className="mb-1.5 block text-sm font-medium">
            Name
          </label>
          <input
            id="name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Nama kamu"
            className={inputClass}
            required
          />
        </div>
        <div>
          <label htmlFor="email" className="mb-1.5 block text-sm font-medium">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="nama@email.com"
            className={inputClass}
            required
          />
        </div>
      </div>

      <div>
        <label htmlFor="subject" className="mb-1.5 block text-sm font-medium">
          Subject
        </label>
        <select
          id="subject"
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
          className={inputClass}
        >
          {contactTopics.map((topic) => (
            <option key={topic}>{topic}</option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="message" className="mb-1.5 block text-sm font-medium">
          Message
        </label>
        <textarea
          id="message"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          rows={6}
          placeholder="Ceritakan kebutuhan atau pertanyaanmu…"
          className={inputClass}
          required
        />
      </div>

      <button
        type="submit"
        disabled={!valid || !supportEmail}
        className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-nusa-primary px-6 py-3.5 font-semibold text-on-brand transition-colors hover:bg-nusa-primarydark disabled:opacity-40 sm:w-auto"
      >
        <Send aria-hidden="true" className="h-4 w-4" />
        {supportEmail ? `Kirim ke ${supportEmail}` : "Kirim pesan"}
      </button>

      {supportEmail && sent && (
        <p className="flex items-start gap-2 rounded-xl bg-nusa-primary/5 p-4 text-sm text-foreground">
          <Mail aria-hidden="true" className="mt-0.5 h-4 w-4 shrink-0 text-brand" />
          Berkas email akan terbuka dari aplikasi email kamu. Jika tidak
          terbuka, kirim langsung ke {supportEmail}.
        </p>
      )}

      {!supportEmail && (
        <p className="flex items-start gap-2 rounded-xl bg-nusa-accent/10 p-4 text-sm text-foreground">
          <Mail aria-hidden="true" className="mt-0.5 h-4 w-4 shrink-0 text-accent-foreground" />
          Email dukungan resmi belum dikonfigurasi untuk rilis publik. Saat
          tersedia, formulir ini akan mengirim ke alamat tersebut.
        </p>
      )}
    </form>
  );
}