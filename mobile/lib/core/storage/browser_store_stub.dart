import 'key_value_store.dart';

/// Only the web has a browser storage; elsewhere this is never called.
KeyValueStore browserStore() => throw UnsupportedError('The browser storage is only on the web.');
