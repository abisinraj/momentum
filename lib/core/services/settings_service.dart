
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGemini, key);
  }

  Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGemini);
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
