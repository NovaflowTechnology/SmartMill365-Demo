import 'dart:html' as html;

abstract class KeyValueStore {
  String? operator [](String key);
  void operator []=(String key, String value);
  bool containsKey(String key);
  void remove(String key);
}

class _WebStore implements KeyValueStore {
  final html.Storage _storage;
  _WebStore(this._storage);

  @override
  String? operator [](String key) => _storage[key];

  @override
  void operator []=(String key, String value) {
    _storage[key] = value;
  }

  @override
  bool containsKey(String key) => _storage.containsKey(key);

  @override
  void remove(String key) {
    _storage.remove(key);
  }
}

final KeyValueStore store = _WebStore(html.window.localStorage);

