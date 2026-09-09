import {
  BarChart3,
  BellRing,
  Database,
  Fingerprint,
  Landmark,
  LayoutDashboard,
  Lock,
  PieChart,
  Search,
  ShieldCheck,
  ShoppingBag,
  Tag,
  Target,
  Wallet,
  type LucideIcon,
} from "lucide-react";

// Shared page content.

export interface Feature {
  title: string;
  description: string;
  icon: LucideIcon;
}

export const features: Feature[] = [
  {
    title: "Dashboard Keuangan",
    description:
      "Total saldo, pemasukan, pengeluaran, dan arus kas bulanan dalam satu layar yang mudah dipahami.",
    icon: LayoutDashboard,
  },
  {
    title: "Catatan Transaksi",
    description:
      "Catat pemasukan, pengeluaran, dan transfer antar akun secara manual dengan cepat.",
    icon: Wallet,
  },
  {
    title: "Akun Keuangan",
    description:
      "Kelola kas, rekening bank, e-wallet, hingga akun kustom sesuai kebutuhanmu.",
    icon: Landmark,
  },
  {
    title: "Budget",
    description:
      "Atur batas pengeluaran per kategori dan tahu kapan kamu mendekati batas.",
    icon: Target,
  },
  {
    title: "Tujuan Keuangan",
    description:
      "Tetapkan tujuan keuangan seperti dana darurat atau tabungan, lalu pantau progresnya.",
    icon: ShoppingBag,
  },
  {
    title: "Laporan Otomatis",
    description:
      "Ringkasan harian, mingguan, bulanan, dan tahunan dihitung otomatis dari catatanmu.",
    icon: BarChart3,
  },
  {
    title: "Kategori",
    description:
      "Kelola kategori pemasukan dan pengeluaran sesuai gaya hidupmu.",
    icon: Tag,
  },
  {
    title: "Search & Filter",
    description:
      "Temukan transaksi apa pun dengan cepat menggunakan pencarian dan filter.",
    icon: Search,
  },
];

export const trustPoints = [
  {
    icon: Database,
    title: "Data Milikmu",
    description: "Catatan keuangan hanya bisa diakses oleh akunmu sendiri.",
  },
  {
    icon: ShieldCheck,
    title: "Keamanan Berlapis",
    description: "Autentikasi, PIN, dan kebijakan akses di setiap baris data.",
  },
  {
    icon: Wallet,
    title: "Pencatatan Mudah",
    description: "Input sederhana, tanpa perlu mengerti akuntansi.",
  },
  {
    icon: PieChart,
    title: "Laporan Otomatis",
    description: "Rangkuman keuangan dirangkum untukmu secara otomatis.",
  },
  {
    icon: Lock,
    title: "Cloud Sync",
    description: "Data tersinkronisasi lintas perangkat melalui akunmu.",
  },
];

export const trustTagline = "Catat sekali, NUSARTA merapikan sisanya.";

export interface Step {
  title: string;
  description: string;
  icon: LucideIcon;
}

export const howItWorksSteps: Step[] = [
  {
    title: "Buat akun NUSARTA",
    description:
      "Daftar dengan email dan buat PIN 6 digit untuk keamanan tambahan.",
    icon: BellRing,
  },
  {
    title: "Tambahkan akun keuangan",
    description:
      "Tambahkan kas, rekening bank, atau e-wallet sebagai akun manual.",
    icon: Landmark,
  },
  {
    title: "Catat pemasukan & pengeluaran",
    description:
      "Catat setiap transaksi secara manual sesuai kejadian sebenarnya.",
    icon: Wallet,
  },
  {
    title: "Pantau laporan otomatis",
    description:
      "NUSARTA merangkum laporan, budget, dan tujuan keuanganmu.",
    icon: BarChart3,
  },
];

export const securityPoints: { icon: LucideIcon; title: string; description: string }[] = [
  {
    icon: Lock,
    title: "Autentikasi aman",
    description:
      "Masuk dilakukan melalui Supabase Auth dengan sesi terenkripsi.",
  },
  {
    icon: Fingerprint,
    title: "PIN & biometrik",
    description:
      "Buka aplikasi dengan PIN 6 digit atau biometrik perangkat.",
  },
  {
    icon: Database,
    title: "Kebijakan akses data",
    description:
      "Setiap pengguna hanya bisa membaca dan mengubah datanya sendiri (Row Level Security).",
  },
  {
    icon: ShieldCheck,
    title: "Penyimpanan aman",
    description:
      "PIN tidak pernah disimpan apa adanya dan detail sensitif disimpan secara terenkripsi.",
  },
];

export interface FaqItem {
  question: string;
  answer: string;
}

export const faqs: FaqItem[] = [
  {
    question: "Apa itu NUSARTA?",
    answer:
      "NUSARTA adalah aplikasi keuangan pribadi yang membantu mencatat, memahami, dan mengendalikan keuangan pribadi secara manual.",
  },
  {
    question: "Apakah NUSARTA menyimpan uang saya?",
    answer:
      "Tidak. NUSARTA hanya mencatat keuangan, bukan menyimpan uang, menerima setoran, atau menjadi pihak yang mengelola dana.",
  },
  {
    question: "Apakah NUSARTA terhubung langsung ke rekening bank?",
    answer:
      "NUSARTA V1 tidak terhubung ke rekening bank atau e-wallet. Saldo dan transaksi dicatat secara manual oleh pengguna.",
  },
  {
    question: "Apakah transaksi otomatis?",
    answer:
      "Tidak. Di V1, seluruh transaksi dicatat secara manual. Fitur sinkronisasi bank/e-wallet direncanakan untuk pengembangan masa depan melalui integrasi resmi.",
  },
  {
    question: "Apakah NUSARTA aman?",
    answer:
      "NUSARTA menggunakan autentikasi aman, PIN terenkripsi, dukungan biometrik, dan kebijakan akses data per pengguna (Row Level Security) pada setiap catatan keuangan.",
  },
  {
    question: "Apakah ada fingerprint?",
    answer:
      "Ya. Pada perangkat yang mendukung, NUSARTA dapat dibuka menggunakan fingerprint atau pengenalan wajah. Jika biometrik gagal, pengguna tetap bisa membuka dengan PIN.",
  },
  {
    question: "Apa yang terjadi jika lupa PIN?",
    answer:
      "PIN bersifat lokal di perangkat dan tidak disimpan dalam bentuk asli. Jika lupa, keluarlah dari akun (logout) lalu masuk kembali — PIN lokal dihapus saat logout, sehingga kamu dapat membuat PIN baru. Informasi lebih lanjut di dokumentasi keamanan.",
  },
  {
    question: "Apakah data tersimpan di cloud?",
    answer:
      "Ya. Catatan keuangan tersinkronisasi melalui cloud (Supabase) agar dapat diakses lintas perangkat setelah masuk dengan akun yang sama.",
  },
  {
    question: "Apakah bisa digunakan tanpa internet?",
    answer:
      "V1 membutuhkan koneksi internet untuk masuk dan menyinkronkan data. Fitur offline penuh dipertimbangkan untuk pengembangan masa depan.",
  },
  {
    question: "Apakah NUSARTA gratis?",
    answer:
      "NUSARTA V1 tersedia gratis untuk penggunaan mencatat keuangan pribadi. Model ini dapat berkembang di masa depan dengan pemberitahuan terlebih dahulu.",
  },
  {
    question: "Apakah nanti bisa transfer uang?",
    answer:
      "NUSARTA V1 belum melakukan transfer uang asli. Fitur connected-finance direncanakan untuk pengembangan masa depan melalui integrasi resmi dengan penyedia yang berizin.",
  },
];

export const roadmapPhases = [
  {
    version: "V1 — Personal Finance",
    status: "Current" as const,
    items: [
      "Akun manual (Kas, Bank, E-wallet, Kustom)",
      "Transaksi (pemasukan, pengeluaran, pindah saldo)",
      "Laporan",
      "Budget",
      "Tujuan keuangan",
      "Buka dengan biometrik",
      "PIN 6 digit",
      "Sinkronisasi cloud",
    ],
  },
  {
    version: "V1.5 — Foundation",
    status: "Planned" as const,
    items: [
      "Fondasi multi-akun & katalog institusi",
      "Fondasi koneksi akun (bank / e-wallet)",
      "Fondasi transfer & penerima",
      "Manajemen perangkat & audit keamanan",
      "Notifikasi & gerbang fitur",
    ],
  },
  {
    version: "V2 — Smart Finance",
    status: "Planned" as const,
    items: [
      "Impor transaksi",
      "Kategorisasi otomatis",
      "Hubungkan bank / e-wallet yang didukung resmi",
      "Sinkronisasi transaksi",
    ],
  },
  {
    version: "V3 — Connected Finance",
    status: "Future" as const,
    items: [
      "Integrasi API finansial resmi",
      "Sinkronisasi saldo bank / e-wallet",
      "Transfer uang asli yang didukung hukum dan teknis",
      "Manajemen penerima",
      "Konfirmasi aman",
    ],
  },
];

export interface ChangeLogEntry {
  version: string;
  build?: string;
  date: string;
  channel: "stable" | "beta";
  added: string[];
  fixed: string[];
  improved: string[];
}

export const changelog: ChangeLogEntry[] = [
  {
    version: "1.0.0",
    build: "+1",
    date: "2026-09-06",
    channel: "stable",
    added: [
      "Akun manual (Kas, Bank, E-wallet, Kustom)",
      "Transaksi pemasukan & pengeluaran",
      "Pindah saldo internal",
      "Dashboard",
      "Laporan (harian, mingguan, bulanan, tahunan)",
      "Budget",
      "Tujuan keuangan",
      "PIN 6 digit",
      "Buka dengan biometrik",
      "Auto-lock",
      "Sinkronisasi cloud",
    ],
    fixed: [],
    improved: ["Pencatatan transaksi lebih cepat", "Desain antarmuka premium"],
  },
];

export const releaseChannels = [
  {
    name: "Stable",
    description:
      "Rilis resmi yang siap dipakai. Versi ini direkomendasikan untuk semua pengguna.",
    active: true,
  },
  {
    name: "Beta",
    description:
      "Rilis uji untuk fitur terbaru. Belum aktif sampai pengujian selesai.",
    active: false,
  },
];

export const accountPresets = [
  "Cash",
  "BCA",
  "BRI",
  "BNI",
  "Mandiri",
  "SeaBank",
  "Jago",
  "GoPay",
  "DANA",
  "OVO",
  "ShopeePay",
  "Custom",
];

export const reportKinds = [
  { label: "Daily", value: "Daily" },
  { label: "Weekly", value: "Weekly" },
  { label: "Monthly", value: "Monthly" },
  { label: "Yearly", value: "Yearly" },
];

export const appScreens = {
  alt: "NUSARTA dashboard menunjukkan saldo, pemasukan, dan pengeluaran",
};

export const contactTopics = [
  "Akun",
  "Masalah aplikasi",
  "Keamanan",
  "Masukan",
  "Lainnya",
];

export const supportMethods = [
  {
    icon: Lock,
    title: "Pusat Bantuan",
    description: "Lihat FAQ untuk jawaban cepat atas pertanyaan umum.",
    href: "/faq",
    label: "Buka FAQ",
  },
];