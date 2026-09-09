# Payments — Future (V2/V3 foundation)

Dokumen ini menjelaskan **rencana** integrasi pembayaran/finansial. Tidak
ada fitur payment yang aktif di V1, dan **tidak akan diaktifkan tanpa
provider resmi**.

## Prinsip inti

1. NUSARTA **bukan** bank dan **bukan** custodian dana.
2. Uang tetap pada rekening/e-wallet asli pengguna.
3. Integrasi hanya lewat provider/API **resmi**.
4. Jangan pernah: scraping, automation UI, minta password internet banking,
   simulasikan "connected bank" dengan data hardcoded.
5. Klaim hanya: "katalog institusi ada" ≠ "integrasi tersedia".
   `institutions.provider_support.integration_available` lah yang menandai
   ketersediaan.

## Arsitektur target

```
Flutter / Web
      ↓  HTTPS (session user)
NUSARTA Backend API
      ↓  Provider Adapter (adapter pattern)
Official Provider (bank / e-wallet / payment)
      ↓
Bank / Wallet
```

- Secret provider **hanya** di server.
- Business logic NUSARTA tidak bergantung pada satu provider.

## Provider adapter (konsep)

```ts
interface PaymentProvider {
  listInstitutions(): Promise<Institution[]>;
  createConnection(...): Promise<Connection>;
  refreshConnection(...); revokeConnection(...);
  getAccounts(...); getBalance(...); getTransactions(...);
  validateRecipient(...); createTransfer(...); getTransferStatus(...);
  handleWebhook(event): Promise<void>;
}
```

Implementasi per-provider di masa depan (mis. via injeksi). Tidak ada
implementasi dummy di repo sekarang.

## Webhook

Saat provider aktif, webhook harus:

- verify signature
- validate timestamp (anti-replay)
- idempotent
- map event provider → internal event
- update transfer secara aman (perubahan status hanya dari backend/provider)
- audit processing

Final status transfer berasal dari **backend/provider**, bukan dari client.

## Idempotency

- `future_transfers.idempotency_key` + unique partial index.
- Tujuan: tekan dua kali ≠ transfer ganda.

## Token / credential

- Jangan simpan access token mentah.
- Bila token wajib disimpan: enkripsi **server-side**; `service_role` /
  provider secret tidak pernah di repository, Flutter, atau web client.
- `account_connections.scopes` dan `consent_expires_at` melacak persetujuan.

## Transfer status

`draft → awaiting_authorization → pending → processing → success`
(+ `failed`, `reversed`, `cancelled`).

## Tidak dilakukan sekarang

- Endpoint transfer real tanpa provider
- Koneksi bank/e-wallet nyata
- Klaim "semua bank/e-wallet didukung"