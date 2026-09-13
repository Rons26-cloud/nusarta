import 'package:local_auth/local_auth.dart';
import 'auto_lock_service.dart';
import 'pin_service.dart';
import 'secure_store.dart';

class BiometricCapability {
  const BiometricCapability(
      {this.supported = false, this.canCheck = false, this.types = const []});
  final bool supported;
  final bool canCheck;
  final List<BiometricType> types;
  bool get available => supported && canCheck && types.isNotEmpty;
  bool get fingerprint => types.contains(BiometricType.fingerprint);
  bool get face => types.contains(BiometricType.face);
  bool get generic => available && !fingerprint && !face;
}

class BiometricService {
  BiometricService._();
  static final LocalAuthentication _auth = LocalAuthentication();
  static bool _authenticating = false;
  static bool get authenticating => _authenticating;

  static Future<BiometricCapability> capability() async {
    try {
      return BiometricCapability(
        supported: await _auth.isDeviceSupported(),
        canCheck: await _auth.canCheckBiometrics,
        types: await _auth.getAvailableBiometrics(),
      );
    } catch (_) {
      return const BiometricCapability();
    }
  }

  static Future<bool> isSupported() async => (await capability()).supported;
  static Future<bool> canAuthenticate() async => (await capability()).available;
  static Future<bool> get isEnabled => AppSecureStore.isBiometricEnabled;

  static Future<bool> _authenticate() async {
    if (_authenticating ||
        !await PinService.isSet ||
        !await canAuthenticate()) {
      return false;
    }
    _authenticating = true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi identitas untuk membuka NUSARTA',
        options:
            const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } catch (_) {
      return false;
    } finally {
      _authenticating = false;
    }
  }

  static Future<bool> unlock() async {
    if (!await isEnabled) return false;
    final ok = await _authenticate();
    if (ok) await AutoLockService.recordActivity();
    return ok;
  }

  static Future<bool> enable() async {
    if (!await _authenticate()) return false;
    await setEnabled(true);
    return true;
  }

  static Future<void> setEnabled(bool value) =>
      AppSecureStore.setBiometricEnabled(value);
}
