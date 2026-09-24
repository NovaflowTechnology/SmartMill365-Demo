abstract class KeyValueStore {
  String? operator [](String key);
  void operator []=(String key, String value);
  bool containsKey(String key);
  void remove(String key);
}

class _MemoryStore implements KeyValueStore {
  final Map<String, String> _map = <String, String>{};

  @override
  String? operator [](String key) => _map[key];

  @override
  void operator []=(String key, String value) {
    _map[key] = value;
  }

  @override
  bool containsKey(String key) => _map.containsKey(key);

  @override
  void remove(String key) {
    _map.remove(key);
  }
}

final KeyValueStore store = _MemoryStore();

