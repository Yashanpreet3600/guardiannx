import 'package:shared_preferences/shared_preferences.dart';

/// Keys for small values kept on the phone.
class LocalKeys {
  LocalKeys._();

  static const language = 'app_language';

  // Onboarding progress, so setup resumes where it stopped.
  static const obProfileDone = 'ob_profile_done';
  static const obPermissionsDone = 'ob_permissions_done';

  // Cached profile, so the home screen opens without internet.
  static const cachedRole = 'cached_role';
  static const cachedName = 'cached_name';
  static const cachedOnboardingDone = 'cached_onboarding_done';

  // SOS: everything an SOS needs is kept on the phone, so it works offline.
  static const activeSos = 'sos_active_session';
  static const sosQueue = 'sos_offline_queue';
  static const cachedContacts = 'cached_contacts';
  static const cachedSosSettings = 'cached_sos_settings';
  static const lastPosition = 'last_position';
}

/// Small wrapper around SharedPreferences, loaded once at startup.
class LocalStore {
  LocalStore._();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getString(String key) => _prefs.getString(key);

  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static bool getBool(String key) => _prefs.getBool(key) ?? false;

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Clears everything tied to the signed-in user but keeps the language.
  static Future<void> clearUserData() async {
    final language = getString(LocalKeys.language);
    await _prefs.clear();
    if (language != null) await setString(LocalKeys.language, language);
  }
}
