/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  /// Base URL of the CarWash API. Defaults to the local Laravel server, which a phone reaches
  /// over USB after `adb reverse tcp:8000 tcp:8000`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
}
