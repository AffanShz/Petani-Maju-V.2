import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// LocalStorage berbasis flutter_secure_storage untuk menyimpan session
/// Supabase (JWT + refresh token) secara terenkripsi (Android Keystore /
/// iOS Keychain), menggantikan SharedPreferences yang menyimpan plaintext.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: _sessionKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
