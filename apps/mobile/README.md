# NUSARTA Mobile

Flutter app for personal finance (manual recording).

## Requirements

- Flutter 3.x (Dart >= 3.3)
- Android device/emulator (min SDK 26)

## Setup

```bash
cd apps/mobile
flutter pub get
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
# fill SUPABASE_URL / SUPABASE_ANON_KEY
flutter run
```

## Configuration

`app_config.dart` is git-ignored. Provide via `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Security model

- PIN stored as salted PBKDF2-style hash (never plaintext) in `flutter_secure_storage`.
- Biometric unlock (fingerprint / face) via `local_auth`. Used to unlock only.
- Auto-lock after N minutes of inactivity.
- All data through Supabase with Row Level Security — the client uses the anon key only.

## Testing

```bash
flutter format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Release (Android APK)

```bash
flutter build apk --release
# update packages/config/src/release.ts with the resulting file size + SHA-256
sha256sum build/app/outputs/flutter-apk/app-release.apk
```

See `docs/RELEASE.md` for the website integration.