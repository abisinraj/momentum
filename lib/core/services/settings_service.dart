
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_service.g.dart';

class SettingsService {
  static const String _keyPexels = 'api_key_pexels';
  static const String _keyUnsplash = 'api_key_unsplash';
  static const String _keyOpenAi = 'api_key_openai';
  static const String _keyGemini = 'gemini_api_key';
  static const String _keyRestTimer = 'rest_timer_seconds';
  static const String _keyWeightUnit = 'weight_unit'; // 'kg' or 'lbs'
  static const String _keyWidgetTheme = 'widget_theme'; // 'classic', 'liquid_glass'

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> setWidgetTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWidgetTheme, theme);
  }

  Future<String> getWidgetTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWidgetTheme) ?? 'classic';
  }

  Future<void> setRestTimer(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRestTimer, seconds);
  }

  Future<int> getRestTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRestTimer) ?? 60; // Default 60s
  }

  Future<void> setPexelsKey(String key) async {
    await _storage.write(key: _keyPexels, value: key);
  }

  Future<String?> getPexelsKey() async {
    // 1. Try secure storage
    String? value = await _storage.read(key: _keyPexels);
    if (value != null) return value;
    
    // 2. Migration: Check legacy prefs
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_keyPexels);
    
    // 3. If found, migrate to secure storage
    if (value != null) {
      await _storage.write(key: _keyPexels, value: value);
      await prefs.remove(_keyPexels);
    }
    return value;
  }

  Future<void> setUnsplashKey(String key) async {
    await _storage.write(key: _keyUnsplash, value: key);
  }

  Future<String?> getUnsplashKey() async {
    String? value = await _storage.read(key: _keyUnsplash);
    if (value != null) return value;
    
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_keyUnsplash);
    
    if (value != null) {
      await _storage.write(key: _keyUnsplash, value: value);
      await prefs.remove(_keyUnsplash);
    }
    return value;
  }
  
  Future<void> setOpenAiKey(String key) async {
    await _storage.write(key: _keyOpenAi, value: key);
  }

  Future<String?> getOpenAiKey() async {
    String? value = await _storage.read(key: _keyOpenAi);
    if (value != null) return value;
    
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_keyOpenAi);
    
    if (value != null) {
      await _storage.write(key: _keyOpenAi, value: value);
      await prefs.remove(_keyOpenAi);
    }
    return value;
  }

  Future<void> setGeminiKey(String key) async {
    await _storage.write(key: _keyGemini, value: key);
  }

  Future<String?> getGeminiKey() async {
    String? value = await _storage.read(key: _keyGemini);
    if (value != null) return value;
    
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_keyGemini);
    
    if (value != null) {
      await _storage.write(key: _keyGemini, value: value);
      await prefs.remove(_keyGemini);
    }
    return value;
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWeightUnit, unit);
  }

  Future<String> getWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWeightUnit) ?? 'kg'; // Default kg
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

@riverpod
Future<int> restTimer(Ref ref) async {
  return ref.watch(settingsServiceProvider).getRestTimer();
}

@riverpod
Future<String> weightUnit(Ref ref) async {
  return ref.watch(settingsServiceProvider).getWeightUnit();
}

@riverpod
Future<String> widgetTheme(Ref ref) async {
  // Watch settings service changes? No, settingsService isn't a notifier. 
  // We should invalidate this provider when setting updates.
  return ref.watch(settingsServiceProvider).getWidgetTheme();
}
