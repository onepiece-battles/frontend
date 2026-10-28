import 'dart:collection';
import 'dart:typed_data';
import '../utils/image_helper.dart';

/// An LRU image cache that limits both the number of entries and total
/// memory usage to prevent unbounded growth in long-running sessions.
///
/// On access, entries are bumped to the most-recently-used position so the
/// eviction policy discards the least-recently-used entries first.
class ImageCacheManager {
  // ── Limits ────────────────────────────────────────────────────────────────
  static const int _maxEntries = 200;
  static const int _maxMemoryBytes = 50 * 1024 * 1024; // 50 MB

  // ── Storage ───────────────────────────────────────────────────────────────
  /// LRU cache.  [LinkedHashMap] preserves insertion order so we can remove
  /// and re-insert on every hit to keep MRU entries at the end and LRU at
  /// the front.
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  /// Track each entry's byte size for accurate memory accounting.
  static final Map<String, int> _entrySizes = {};

  /// Running total of bytes currently stored.
  static int _totalMemoryBytes = 0;
  static final Map<String, Future<Uint8List>> _pending = {};
  static int _generation = 0;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Number of cached images.
  static int get cacheSize => _cache.length;

  /// Current memory footprint in bytes.
  static int get memoryUsageBytes => _totalMemoryBytes;

  /// Current memory footprint in megabytes.
  static double get memoryUsageMB => _totalMemoryBytes / (1024 * 1024);

  /// Returns the decoded image bytes for [uri], fetching and caching the
  /// image from the network if it is not already in the cache.
  ///
  /// Cache hits bump the entry to the MRU end so it won't be evicted soon.
  /// Cache misses are fetched, decoded, and inserted — evicting LRU entries
  /// first when the cache exceeds [_maxEntries] or [_maxMemoryBytes].
  static Future<Uint8List> getImage(String uri, {bool? fullImage}) async {
    final cacheKey = _cacheKey(uri, fullImage);

    // ── Cache hit: bump to MRU end ──────────────────────────────────────
    if (_cache.containsKey(cacheKey)) {
      final data = _cache.remove(cacheKey)!;
      _cache[cacheKey] = data;
      return data;
    }

    return _pending.putIfAbsent(
        cacheKey, () => _load(uri, fullImage, cacheKey, _generation));
  }

  static Future<Uint8List> _load(
      String uri, bool? fullImage, String key, int generation) async {
    try {
      final bytes =
          await ImageHelper.loadImageBytesByUri(uri, fullImage: fullImage);
      if (generation == _generation) {
        _evictIfNeeded(bytes.length);
        _cache[key] = bytes;
        _entrySizes[key] = bytes.length;
        _totalMemoryBytes += bytes.length;
      }
      return bytes;
    } finally {
      if (generation == _generation) _pending.remove(key);
    }
  }

  /// Remove a single entry from the cache.
  static void remove(String uri, {bool? fullImage}) {
    final cacheKey = _cacheKey(uri, fullImage);
    final removed = _cache.remove(cacheKey);
    if (removed != null) {
      _totalMemoryBytes -= (_entrySizes[cacheKey] ?? 0);
      _entrySizes.remove(cacheKey);
    }
  }

  /// Discard every cached entry and reset all counters.
  static void clear() {
    _generation++;
    _pending.clear();
    _cache.clear();
    _entrySizes.clear();
    _totalMemoryBytes = 0;
  }

  // ── Eviction ──────────────────────────────────────────────────────────────

  /// Evicts LRU entries until there is room for an image of [incomingSize]
  /// bytes without exceeding either the count or memory limit.
  static void _evictIfNeeded(int incomingSize) {
    while (_cache.isNotEmpty) {
      final bool overCount = _cache.length >= _maxEntries;
      final bool overMemory =
          _totalMemoryBytes + incomingSize > _maxMemoryBytes;
      if (!overCount && !overMemory) break;

      // The first key of a LinkedHashMap is the least-recently-used entry.
      final String lruKey = _cache.keys.first;
      final Uint8List? removed = _cache.remove(lruKey);
      if (removed != null) {
        _totalMemoryBytes -= (_entrySizes[lruKey] ?? 0);
        _entrySizes.remove(lruKey);
      }
    }
  }

  static String _cacheKey(String uri, bool? fullImage) =>
      '${fullImage == true ? 'full' : 'default'}:$uri';
}
