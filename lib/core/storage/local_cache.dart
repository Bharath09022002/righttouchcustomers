import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight offline persistence cache powered by SharedPreferences.
/// Caches essential catalogs, services, and profile snapshots so the app
/// loads instantly even during slow connectivity or offline modes.
class LocalCacheService {
  static const String _keyCategories = 'cached_categories_v1';
  static const String _keyServices = 'cached_services_v1';
  static const String _keyProfile = 'cached_profile_v1';

  static LocalCacheService? _instance;
  static LocalCacheService get instance => _instance ??= LocalCacheService();

  Future<void> cacheCategories(List<Map<String, dynamic>> rawList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCategories, jsonEncode(rawList));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyCategories);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheProfile(Map<String, dynamic> rawUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfile, jsonEncode(rawUser));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyProfile);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyServices);
      await prefs.remove(_keyProfile);
    } catch (_) {}
  }
}
