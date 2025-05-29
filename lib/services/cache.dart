class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(minutes: 30);

  void setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  dynamic getCache(String key) {
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheTTL) {
        return _cache[key];
      } else {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    return null;
  }

  void invalidateCache(String keyPrefix) {
    _cache.keys
        .where((key) => key.startsWith(keyPrefix))
        .toList()
        .forEach((key) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    });
  }
}