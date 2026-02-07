
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_service.g.dart';

class SettingsService {
  static const String _keyPexels = 'api_key_pexels';
  static const String _keyUnsplash = 'api_key_unsplash';
  static const String _keyGemini = 'gemini_api_key';
  static const String _keyRestTimer = 'rest_timer_seconds';
  static const String _keyWeightUnit = 'weight_unit'; // 'kg' or 'lbs'
  static const String _keyWidgetTheme = 'widget_theme'; // 'classic', 'liquid_glass'
  static const String _keyAppTheme = 'app_theme'; // 'black', 'heavenly'
  static const String _keyTimeFormat = 'time_format'; // '12h', '24h'
  static const String _keyModelRotationMode = 'model_rotation_mode'; // 'horizontal', 'full'
  static const String _keyGeminiModel = 'gemini_model';
  static const String _keyPermissionsHandled = 'permissions_handled';
  static const String _keyBoxingGameEnabled = 'boxing_game_enabled';

  final _storage = const FlutterSecureStorage();

  Future<void> setModelRotationMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModelRotationMode, mode);
  }

  Future<String> getModelRotationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyModelRotationMode) ?? 'horizontal';
  }

  Future<void> setWidgetTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWidgetTheme, theme);
  }

  Future<String> getWidgetTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWidgetTheme) ?? 'classic';
  }

  Future<void> setAppTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppTheme, theme);
  }

  Future<String> getAppTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppTheme) ?? 'black';
  }

  Future<void> setRestTimer(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRestTimer, seconds);
  }

  Future<int> getRestTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRestTimer) ?? 60; // Default 60s
  }

  Future<void> setBoxingGameEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBoxingGameEnabled, enabled);
  }

  Future<bool> getBoxingGameEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBoxingGameEnabled) ?? true; // Default true
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

  Future<void> setGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiModel, model);
  }

  Future<String> getGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiModel) ?? 'gemini-1.5-flash'; // Default model
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWeightUnit, unit);
  }

  Future<String> getWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWeightUnit) ?? 'kg'; // Default kg
  }

  Future<void> setPermissionsHandled(bool handled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionsHandled, handled);
  }

  Future<bool> getPermissionsHandled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionsHandled) ?? false;
  }

  Future<void> setTimeFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimeFormat, format);
  }

  Future<String> getTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTimeFormat) ?? '12h';
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
Future<String?> geminiApiKey(Ref ref) async {
  return ref.watch(settingsServiceProvider).getGeminiKey();
}

@riverpod
class GeminiModel extends _$GeminiModel {
  @override
  Future<String> build() async {
    return ref.read(settingsServiceProvider).getGeminiModel();
  }

  Future<void> setModel(String model) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsServiceProvider).setGeminiModel(model);
      return model;
    });
  }
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
class WidgetTheme extends _$WidgetTheme {
  @override
  Future<String> build() async {
    return ref.read(settingsServiceProvider).getWidgetTheme();
  }

  Future<void> setTheme(String theme) async {
    state = await AsyncValue.guard(() async {
      await ref.read(settingsServiceProvider).setWidgetTheme(theme);
      return theme;
    });
  }
}

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  Future<String> build() async {
    return ref.read(settingsServiceProvider).getAppTheme();
  }

  Future<void> setTheme(String theme) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsServiceProvider).setAppTheme(theme);
      return theme;
    });
  }
}

@riverpod
class ModelRotationMode extends _$ModelRotationMode {
  @override
  Future<String> build() async {
    return ref.read(settingsServiceProvider).getModelRotationMode();
  }

  Future<void> setMode(String mode) async {
    state = await AsyncValue.guard(() async {
      await ref.read(settingsServiceProvider).setModelRotationMode(mode);
      return mode;
    });
  }
}

@riverpod
class TimeFormat extends _$TimeFormat {
  @override
  Future<String> build() async {
    return ref.read(settingsServiceProvider).getTimeFormat();
  }

  Future<void> setFormat(String format) async {
    state = await AsyncValue.guard(() async {
      await ref.read(settingsServiceProvider).setTimeFormat(format);
      return format;
    });
  }
}

@riverpod
class BoxingGameEnabled extends _$BoxingGameEnabled {
  @override
  Future<bool> build() async {
    return ref.read(settingsServiceProvider).getBoxingGameEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = await AsyncValue.guard(() async {
      await ref.read(settingsServiceProvider).setBoxingGameEnabled(enabled);
      return enabled;
    });
  }
}
