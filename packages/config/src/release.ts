import { apkMetadata } from "./apk-metadata";

export type ReleaseChannel = "stable" | "beta";

export interface ReleaseMeta {
  version: string;
  buildNumber: string;
  releaseDate: string;
  platform: "android";
  channel: ReleaseChannel;
  downloadUrl: string;
  apkFileName: string;
  checksumSha256: string;
  minimumAndroidVersion: string;
  fileSizeMb: string;
  notes: string[];
}

// Android release metadata.
export const currentRelease: ReleaseMeta = {
  version: "1.0.0",
  buildNumber: "1",
  releaseDate: "2026-09-06",
  platform: "android",
  channel: "stable",
  downloadUrl: "/downloads/NUSARTA.apk",
  apkFileName: apkMetadata.fileName,
  checksumSha256: apkMetadata.sha256,
  minimumAndroidVersion: "8.0",
  fileSizeMb: apkMetadata.sizeLabel,
  notes: [
    "Akun manual (Kas, Bank, E-wallet, Kustom)",
    "Transaksi pemasukan & pengeluaran",
    "Pindah saldo internal antar akun",
    "Dashboard dan arus kas bulanan",
    "Laporan (harian, mingguan, bulanan, tahunan)",
    "Budget",
    "Tujuan keuangan",
    "PIN 6 digit",
    "Buka dengan biometrik",
    "Auto-lock",
    "Sinkronisasi cloud via Supabase",
  ],
};

export function getReleaseDownloadUrl(baseUrl?: string): string {
  if (baseUrl) {
    return `${baseUrl.replace(/\/$/, "")}/downloads/${currentRelease.apkFileName}`;
  }
  return `/downloads/${currentRelease.apkFileName}`;
}
