import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localCacheProvider = Provider<LocalCache>((ref) => LocalCache());

class LocalCache {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await prefs;
    return p.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final p = await prefs;
    return p.getInt(key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }

  // Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyContextLength = 'context_length';

  Future<List<String>> getStringList(String key) async {
    final p = await prefs;
    return p.getStringList(key) ?? [];
  }

  Future<void> setStringList(String key, List<String> value) async {
    final p = await prefs;
    await p.setStringList(key, value);
  }
}
