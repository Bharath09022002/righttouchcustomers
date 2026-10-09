import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hardened JWT + refresh-token persistence.
/// All sensitive credentials (access token, refresh token) are exclusively stored
/// in encrypted FlutterSecureStorage (KeyStore / KeyChain).
/// In-memory cache provides fast sync reads for router guards.
class TokenStorage {
  static const _kToken = 'rt_customer_token';
  static const _kRefresh = 'rt_refresh_token';
  static const _kMobile = 'rt_mobile';
  static const _kOnboarded = 'rt_onboarded';
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? cachedToken;

  static void debugValidateJwt(String? token) {
    if (!kDebugMode || token == null || token.isEmpty) return;
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        var normalized = base64Url.normalize(parts[1]);
        final decodedBytes = base64Url.decode(normalized);
        final jsonMap = jsonDecode(utf8.decode(decodedBytes));
        if (jsonMap is Map) {
          final userId = (jsonMap['userId'] ?? jsonMap['id'] ?? jsonMap['_id'] ?? jsonMap['sub'])?.toString() ?? '';
          final is24Hex = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(userId);
          debugPrint('[JWT Debug] Payload userId: "$userId", length: ${userId.length}, is24CharHexObjectId: $is24Hex');
        }
      }
    } catch (e) {
      debugPrint('[JWT Debug] Could not decode token: $e');
    }
  }

  Future<void> saveToken(String token) async {
    cachedToken = token;
    debugValidateJwt(token);
    await _secure.write(key: _kToken, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secure.write(key: _kRefresh, value: token);
  }

  Future<String?> getToken() async {
    cachedToken ??= await _secure.read(key: _kToken);
    return cachedToken;
  }

  Future<String?> getRefreshToken() => _secure.read(key: _kRefresh);

  Future<void> loadCache() async {
    cachedToken = await _secure.read(key: _kToken);
  }

  bool get isLoggedInSync => (cachedToken ?? '').isNotEmpty;

  Future<void> clear() async {
    cachedToken = null;
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kRefresh);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken); // Clean up legacy plaintext key if any
  }

  Future<void> saveMobile(String m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMobile, m);
  }

  Future<String?> getMobile() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kMobile);
  }

  Future<bool> isOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarded) ?? false;
  }

  Future<void> setOnboarded() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, true);
  }
}

