import 'dart:js_interop';

import 'key_value_store.dart';

@JS('localStorage')
external _Storage get _localStorage;

extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

/// The browser's own storage. The secure storage package refuses to run on a page opened over plain http from
/// another device (such as a phone opening this computer's address), so the web keeps the session here; that
/// package kept its encryption key in this same storage anyway.
KeyValueStore browserStore() => const _BrowserStore();

class _BrowserStore implements KeyValueStore {
  const _BrowserStore();

  static const _prefix = 'carwash.';

  @override
  Future<String?> read(String key) async => _localStorage.getItem('$_prefix$key');

  @override
  Future<void> write(String key, String value) async => _localStorage.setItem('$_prefix$key', value);

  @override
  Future<void> delete(String key) async => _localStorage.removeItem('$_prefix$key');
}
