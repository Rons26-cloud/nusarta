Sumber: apps/mobile/build/app/outputs/flutter-apk/NUSARTA.apk
Publik: apps/web/public/downloads/NUSARTA.apk
URL: /downloads/NUSARTA.apk

Copy file sumber sebelum build; jangan pindahkan atau menggantinya dengan file lain.
Dari root: node scripts/generate-apk-metadata.mjs
Jalankan npm run release:metadata lalu npm run release:verify dari root untuk rilis APK.
Build web memakai metadata terlacak dan tidak memerlukan binary APK.

Host NUSARTA.apk di object storage terpisah, bukan Git atau Workers Static Assets.
Isi NEXT_PUBLIC_DOWNLOAD_URL dengan URL HTTPS lengkap APK, lalu build ulang website.
Folder ini hanya untuk APK publik; jangan menyalin credentials atau signing secrets.
