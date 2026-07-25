import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class CachedTileProvider extends TileProvider {
  static String? _cachePath;

  CachedTileProvider();

  /// Pre-initializes the cache directory subpath.
  static Future<void> initialize() async {
    if (_cachePath != null) return;
    try {
      final dbPath = await getDatabasesPath();
      _cachePath = p.join(dbPath, 'tile_cache');
      final directory = Directory(_cachePath!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      debugPrint('CachedTileProvider initialized directory at: $_cachePath');
    } catch (e) {
      debugPrint('Error initializing CachedTileProvider: $e');
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (_cachePath == null) {
      // Fallback if not initialized yet
      return NetworkImage(getTileUrl(coordinates, options));
    }

    final String tilePath = p.join(
      _cachePath!,
      '${coordinates.z}',
      '${coordinates.x}',
      '${coordinates.y}.png',
    );

    final file = File(tilePath);

    if (file.existsSync()) {
      return FileImage(file);
    } else {
      // If file doesn't exist, download it in background and serve NetworkImage
      _downloadAndCache(coordinates, tilePath, options);
      return NetworkImage(getTileUrl(coordinates, options));
    }
  }

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
      }
      client.close();
    } catch (e) {
      // Graceful failure (e.g. offline)
      debugPrint('Failed to download map tile to cache: $e');
    }
  }
}
