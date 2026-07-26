import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/app.dart';
import 'data/database/app_database.dart';
import 'data/mesh/cached_tile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent unhandled Flutter rendering errors from crashing to a black screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError caught in main: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error caught: $error');
    return true; // Handled
  };

  // Mount UI immediately to ensure instant render on physical release builds
  runApp(
    const ProviderScope(
      child: RescueMeshApp(),
    ),
  );

  // Safely perform asynchronous database and tile cache initialization in background
  Future.microtask(() async {
    try {
      await AppDatabase.instance.database;
    } catch (e, stack) {
      debugPrint('Database initialization warning: $e\n$stack');
    }
    try {
      await CachedTileProvider.initialize();
    } catch (e, stack) {
      debugPrint('CachedTileProvider initialization warning: $e\n$stack');
    }
  });
}
