import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'browser_store_stub.dart' if (dart.library.js_interop) 'browser_store_web.dart';
import 'key_value_store.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(kIsWeb ? browserStore() : const SecureKeyValueStore()),
);

/// Keeps the API token, this device's identity and its display preferences: in the phone's secure storage, or
/// the browser's own storage on the web.
///
/// The device identifier and secret survive sign-out so staff can keep switching in by PIN;
/// only the token belongs to the current staff member.
class SessionStorage {
  SessionStorage(this._storage);

  static const _tokenKey = 'api_token';
  static const _deviceIdentifierKey = 'device_identifier';
  static const _deviceSecretKey = 'device_secret';
  static const _themeModeKey = 'theme_mode';

  final KeyValueStore _storage;

  Future<String?> token() => _storage.read(_tokenKey);

  Future<void> saveToken(String token) => _storage.write(_tokenKey, token);

  Future<void> clearToken() => _storage.delete(_tokenKey);

  Future<String?> deviceSecret() => _storage.read(_deviceSecretKey);

  Future<void> saveDeviceSecret(String secret) => _storage.write(_deviceSecretKey, secret);

  /// `light` or `dark`, as last chosen on this device; null before the first choice.
  Future<String?> themeMode() => _storage.read(_themeModeKey);

  Future<void> saveThemeMode(String mode) => _storage.write(_themeModeKey, mode);

  /// A random identifier created on first use and kept for the life of the installation.
  Future<String> deviceIdentifier() async {
    final existing = await _storage.read(_deviceIdentifierKey);
    if (existing != null) {
      return existing;
    }

    final random = Random.secure();
    final identifier = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(_deviceIdentifierKey, identifier);

    return identifier;
  }
}
