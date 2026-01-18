import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_service.g.dart';

class SettingsService {
  static const String _keyPexels = 'api_key_pexels';
  static const String _keyUnsplash = 'api_key_unsplash';
  static const String _keyOpenAi = 'api_key_openai';

  Future<void> setPexelsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPexels, key);
  }

  Future<String?> getPexelsKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPexels);
  }

  Future<void> setUnsplashKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnsplash, key);
  }

  Future<String?> getUnsplashKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUnsplash);
  }
  
  Future<void> setOpenAiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOpenAi, key);
  }

  Future<String?> getOpenAiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOpenAi);
  }
}

@riverpod
SettingsService settingsService(Ref ref) {
  return SettingsService();
}

@riverpod
Future<String?> pexelsApiKey(Ref ref) async {
  return ref.watch(settingsServiceProvider).getPexelsKey();
}

@riverpod
Future<String?> unsplashApiKey(Ref ref) async {
  return ref.watch(settingsServiceProvider).getUnsplashKey();
}
