import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PinCheck { safe, duress, wrong }

/// Stores the safety PIN and duress PIN on this phone only, as salted hashes
/// in encrypted storage. They work offline, which matters during an SOS.
///
/// Safety PIN: really stops the SOS.
/// Duress PIN: looks like it stops the SOS, but alerts keep going.
class PinService {
  PinService._();

  static const pinLength = 4;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _saltKey = 'pin_salt';
  static const _safeKey = 'pin_safe_hash';
  static const _duressKey = 'pin_duress_hash';

  static Future<bool> hasPins() async {
    final safe = await _storage.read(key: _safeKey);
    final duress = await _storage.read(key: _duressKey);
    return safe != null && duress != null;
  }

  static Future<void> savePins({required String safePin, required String duressPin}) async {
    if (safePin == duressPin) throw ArgumentError('The two PINs must be different');
    final salt = _newSalt();
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _safeKey, value: _hash(safePin, salt));
    await _storage.write(key: _duressKey, value: _hash(duressPin, salt));
  }

  static Future<PinCheck> check(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    if (salt == null) return PinCheck.wrong;
    final hash = _hash(pin, salt);
    if (hash == await _storage.read(key: _safeKey)) return PinCheck.safe;
    if (hash == await _storage.read(key: _duressKey)) return PinCheck.duress;
    return PinCheck.wrong;
  }

  /// Rejects PINs an attacker would try first: 1111, 1234, 9876 and so on.
  static bool isWeak(String pin) {
    if (pin.split('').toSet().length == 1) return true;
    const ascending = '01234567890';
    const descending = '09876543210';
    return ascending.contains(pin) || descending.contains(pin);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _safeKey);
    await _storage.delete(key: _duressKey);
  }

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String _newSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }
}
