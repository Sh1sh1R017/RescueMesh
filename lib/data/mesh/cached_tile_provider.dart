import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class CachedTileProvider extends TileProvider {
  static String? _cachePath;
  static final Set<String> _cachedFileKeys = <String>{};

  CachedTileProvider();

  /// Pre-initializes the cache directory subpath and populates in-memory tile index.
  static Future<void> initialize() async {
    if (_cachePath != null) return;
    try {
      final dbPath = await getDatabasesPath();
      _cachePath = p.join(dbPath, 'tile_cache');
      final directory = Directory(_cachePath!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      } else {
        // Populate in-memory index asynchronously to eliminate main-thread file stats during map panning
        final entities = await directory.list(recursive: true).toList();
        for (final entity in entities) {
          if (entity is File) {
            _cachedFileKeys.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing CachedTileProvider: $e');
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (_cachePath == null) {
      return NetworkImage(getTileUrl(coordinates, options));
    }

    final String tilePath = p.join(
      _cachePath!,
      '${coordinates.z}',
      '${coordinates.x}',
      '${coordinates.y}.png',
    );

    // Instant O(1) in-memory lookup without UI raster thread Disk I/O
    if (_cachedFileKeys.contains(tilePath)) {
      return FileImage(File(tilePath));
    } else {
      _downloadAndCache(coordinates, tilePath, options);
      return NetworkImage(getTileUrl(coordinates, options));
    }
  }

  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    return 'https://tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
  }

  Future<void> _downloadAndCache(
    TileCoordinates coordinates,
    String tilePath,
    TileLayer options,
  ) async {
    try {
      final url = getTileUrl(coordinates, options);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        final file = File(tilePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        _cachedFileKeys.add(tilePath); // Update in-memory index
      }
      client.close();
    } catch (e) {
      debugPrint('Failed to download map tile to cache: $e');
    }
  }
}
