import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(const FlutterSecureStorage()),
);

/// Keeps the API token and this device's identity in the platform's secure storage.
///
/// The device identifier and secret survive sign-out so staff can keep switching in by PIN;
/// only the token belongs to the current staff member.
class SessionStorage {
  SessionStorage(this._storage);

  static const _tokenKey = 'api_token';
  static const _deviceIdentifierKey = 'device_identifier';
  static const _deviceSecretKey = 'device_secret';

  final FlutterSecureStorage _storage;

  Future<String?> token() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<String?> deviceSecret() => _storage.read(key: _deviceSecretKey);

  Future<void> saveDeviceSecret(String secret) => _storage.write(key: _deviceSecretKey, value: secret);

  /// A random identifier created on first use and kept for the life of the installation.
  Future<String> deviceIdentifier() async {
    final existing = await _storage.read(key: _deviceIdentifierKey);
    if (existing != null) {
      return existing;
    }

    final random = Random.secure();
    final identifier = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: _deviceIdentifierKey, value: identifier);

    return identifier;
  }
}
