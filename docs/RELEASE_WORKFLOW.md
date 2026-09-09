# NUSARTA Release Workflow

1. Bump `apps/mobile/pubspec.yaml` to a new semantic version and increasing build number.
2. Run `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test` from `apps/mobile`.
3. Build a production signed APK and name the artifact `NUSARTA.apk`.
4. Create and push tag `vX.Y.Z`, then attach `NUSARTA.apk` to the published GitHub Release in `Rons26-cloud/nusarta`.
5. The website reads stable published releases from the public GitHub Releases API; `/releases` and `/download` update without source changes.

The current GitHub APK distribution is temporary. Android installs updates only when the package ID and signing certificate match and the build number increases. Never commit keystores or signing credentials; configure them as CI secrets. A future Google Play release should use a signed AAB and let Play deliver updates while the public release history remains available.

For a release such as `v1.0.1`, set `version: 1.0.1+2`, update notes, run the mobile checks, commit, then push `git tag v1.0.1` and `git push origin v1.0.1`. The tag workflow validates the version, builds `NUSARTA.apk`, publishes checksums, and creates the GitHub Release. Configure the Android signing secrets before enabling production releases. Google Play later uses the same version/build gate with `flutter build appbundle --release` and Play Console delivery.
