import 'package:flutter/foundation.dart';

/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the CarWash API. On the web the API sits next to the app one level up from
  /// `/app/`, so the same build works served both at the server's root (artisan serve) and from
  /// a subfolder (`/carwash/public/app/`). Otherwise it defaults to the local Laravel server,
  /// which a phone reaches over USB after `adb reverse tcp:8000 tcp:8000`; `run-on-wifi` sets
  /// the PC's Wi-Fi address instead.
  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl;
    }
    if (kIsWeb) {
      final base = Uri.base;
      final cut = base.path.lastIndexOf('/app/');
      final root = cut >= 0 ? base.path.substring(0, cut + 1) : '/';
      return '${base.origin}$root/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }
}
