import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight offline persistence cache powered by SharedPreferences and FlutterSecureStorage.
/// Caches essential catalogs and encrypts profile snapshots so customer PII is secure.
class LocalCacheService {
  static const String _keyCategories = 'cached_categories_v1';
  static const String _keyServices = 'cached_services_v1';
  static const String _keyProfile = 'cached_profile_v1';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

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
      await _secure.write(key: _keyProfile, value: jsonEncode(rawUser));
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyProfile); // Clean up legacy plaintext key
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final secureStr = await _secure.read(key: _keyProfile);
      if (secureStr != null && secureStr.isNotEmpty) {
        final decoded = jsonDecode(secureStr);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      // Migration fallback from legacy unencrypted SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final legacyStr = prefs.getString(_keyProfile);
      if (legacyStr != null && legacyStr.isNotEmpty) {
        final decoded = jsonDecode(legacyStr);
        if (decoded is Map<String, dynamic>) {
          await _secure.write(key: _keyProfile, value: legacyStr);
          await prefs.remove(_keyProfile);
          return decoded;
        }
      }
    } catch (_) {}
    return null;
  }

  static const String _keyDefaultAddressId = 'cached_default_address_id_v1';

  Future<void> cacheDefaultAddressId(String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDefaultAddressId, addressId);
    } catch (_) {}
  }

  Future<String?> getCachedDefaultAddressId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDefaultAddressId);
    } catch (_) {}
    return null;
  }

  Future<void> clearAll() async {
    try {
      await _secure.delete(key: _keyProfile);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyServices);
      await prefs.remove(_keyProfile);
      await prefs.remove(_keyDefaultAddressId);
    } catch (_) {}
  }
}
