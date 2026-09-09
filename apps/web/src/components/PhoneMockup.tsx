import { appScreens } from "@/lib/data";
import { ArrowDownLeft, ArrowUpRight, BatteryFull, Home, MoreHorizontal, PieChart, Plus, Signal, User, Wallet, Wifi } from "lucide-react";
import styles from "./PhoneMockup.module.css";

const transactions = [
  { name: "Gaji Bulanan", amount: "Rp 5.200.000", positive: true },
  { name: "Kopi Kenangan", amount: "Rp 75.000", positive: false },
  { name: "Listrik & Air", amount: "Rp 250.000", positive: false },
];
const bars = [35, 55, 40, 70, 50, 85, 60];

export function PhoneMockup({ className = "" }: { className?: string }) {
  return (
    <div role="img" aria-label={appScreens.alt} className={styles.phone + " " + className}>
      <div aria-hidden="true" className="rounded-[2.5rem] border-[6px] border-nusa-deepest bg-card p-3 shadow-xl sm:p-4">
        <div className="flex items-center justify-between px-2 pb-4 pt-1 text-[10px] font-semibold text-foreground">
          <span>09:41</span>
          <span className="flex items-center gap-1">
            <Signal className="h-3 w-3" /><Wifi className="h-3 w-3" /><BatteryFull className="h-3 w-4" />
          </span>
        </div>
        <div className="flex items-center justify-between gap-2">
          <div>
            <p className="text-[10px] text-muted-foreground sm:text-xs">Halo, Selamat Pagi</p>
            <p className="text-xs font-semibold text-foreground sm:text-sm">Nusantara User</p>
          </div>
          <User className="h-7 w-7 rounded-full bg-muted p-1 text-brand" />
        </div>
        <div className="mt-4 rounded-2xl border border-border bg-muted p-3 sm:p-4">
          <p className="text-[10px] font-medium text-muted-foreground sm:text-xs">Total Saldo</p>
          <p className="mt-1 text-[24px] font-bold tracking-tight text-foreground sm:text-[28px]">Rp 8.450.000</p>
          <div className="mt-3 grid grid-cols-2 gap-2">
            <div className="rounded-xl bg-card p-2">
              <p className="text-[10px] text-muted-foreground">Masuk</p>
              <p className="text-[11px] font-semibold text-positive sm:text-xs">Rp 6.2jt</p>
            </div>
            <div className="rounded-xl bg-card p-2">
              <p className="text-[10px] text-muted-foreground">Keluar</p>
              <p className="text-[11px] font-semibold text-negative sm:text-xs">Rp 3.1jt</p>
            </div>
          </div>
        </div>
        <div className="mt-3 rounded-2xl border border-border p-3">
          <p className="text-xs font-semibold text-foreground sm:text-sm">Arus Kas</p>
          <div className="mt-3 flex h-16 items-end gap-2 sm:h-20">
            {bars.map((height, i) => (
              <div key={i} className={"min-w-0 flex-1 rounded-t " + (i === 5 ? "bg-nusa-gold" : "bg-brand/65")} style={{ height: height + "%" }} />
            ))}
          </div>
        </div>
        <div className="mb-2 mt-4 flex items-center justify-between">
          <p className="text-xs font-semibold text-foreground sm:text-sm">Terbaru</p>
          <span className="text-[10px] text-brand sm:text-xs">Lihat Semua</span>
        </div>
        <div className="space-y-2">
          {transactions.map((item) => {
            const Icon = item.positive ? ArrowDownLeft : ArrowUpRight;
            return (
              <div key={item.name} className="flex items-center gap-2 rounded-xl bg-muted px-2 py-2.5">
                <Icon className={"h-5 w-5 shrink-0 " + (item.positive ? "text-positive" : "text-negative")} />
                <span className="min-w-0 flex-1 text-[10px] leading-snug text-foreground sm:text-xs">{item.name}</span>
                <span className={"whitespace-nowrap text-[10px] font-semibold sm:text-[11px] " + (item.positive ? "text-positive" : "text-negative")}>{item.positive ? "+" : "−"} {item.amount}</span>
              </div>
            );
          })}
        </div>
        <div className="mt-4 flex items-center justify-between border-t border-border px-2 pt-3 text-muted-foreground">
          <Home className="h-4 w-4 text-brand" />
          <Wallet className="h-4 w-4" />
          <Plus className="h-8 w-8 rounded-full bg-nusa-gold p-1.5 text-nusa-deepest" />
          <PieChart className="h-4 w-4" />
          <MoreHorizontal className="h-4 w-4" />
        </div>
        <div className="mx-auto mt-4 h-1 w-16 rounded-full bg-foreground/30" />
      </div>
    </div>
  );
}
