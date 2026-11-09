import 'package:flutter/foundation.dart';

/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the CarWash API. On the web it is the server the page came from, so the same build works
  /// whichever address the page is opened by. Otherwise it defaults to the local Laravel server, which a phone
  /// reaches over USB after `adb reverse tcp:8000 tcp:8000`; `run-on-wifi` sets the PC's Wi-Fi address instead.
  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl;
    }
    return kIsWeb ? '${Uri.base.origin}/api/v1' : 'http://127.0.0.1:8000/api/v1';
  }
}
