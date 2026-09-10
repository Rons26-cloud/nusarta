import { Fingerprint, Globe2, LockKeyhole, ShieldCheck } from "lucide-react";

const trust = [
  [ShieldCheck, "Privasi terjaga", "Kontrol data tetap di tanganmu"],
  [Fingerprint, "PIN & biometrik", "Lapisan akses di perangkat"],
  [LockKeyhole, "Akses terlindungi", "Catatan pribadi melalui akunmu"],
  [Globe2, "Untuk Indonesia", "Bahasa dan kebiasaan lokal"],
] as const;

export function TrustStrip() {
  return <section aria-label="Keunggulan NUSARTA" className="border-y border-border bg-card"><div className="mx-auto grid max-w-7xl gap-px bg-border sm:grid-cols-2 lg:grid-cols-4">{trust.map(([Icon, title, text]) => <div key={title} className="flex items-center gap-3 bg-card px-4 py-5 sm:px-6"><Icon aria-hidden="true" className="h-5 w-5 shrink-0 text-brand" /><div><p className="text-sm font-semibold text-foreground">{title}</p><p className="mt-0.5 text-xs text-muted-foreground">{text}</p></div></div>)}</div></section>;
}
