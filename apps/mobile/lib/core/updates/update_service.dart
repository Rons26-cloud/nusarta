import 'package:package_info_plus/package_info_plus.dart';
import '../constants/secure_keys.dart';
import '../security/secure_store.dart';
import 'github_release_source.dart';
import 'update_models.dart';

class UpdateService {
  UpdateService(this.source);
  final UpdateSource source;
  static const cacheInterval = Duration(hours: 8);

  Future<UpdateState> checkForUpdate({bool force = false}) async {
    final last = DateTime.tryParse(await SecureStore.read(SecureKeys.updateCheckedAt) ?? '');
    if (!force && last != null && DateTime.now().difference(last) < cacheInterval) return const UpdateState(UpdateStatus.latest);
    try {
      final info = await PackageInfo.fromPlatform();
      final latest = await source.latestStable();
      await SecureStore.write(SecureKeys.updateCheckedAt, DateTime.now().toIso8601String());
      if (latest == null) return const UpdateState(UpdateStatus.latest);
      return UpdateState(compareVersions(info.version, latest.version) < 0 ? UpdateStatus.updateAvailable : UpdateStatus.latest, release: latest);
    } catch (_) { return const UpdateState(UpdateStatus.error, message: 'Tidak dapat memeriksa pembaruan. Coba lagi.'); }
  }
}
