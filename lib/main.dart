import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/app.dart';
import 'data/database/app_database.dart';
import 'data/mesh/cached_tile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database
  await AppDatabase.instance.database;
  
  // Initialize offline map tile cache
  await CachedTileProvider.initialize();
  
  runApp(
    // ProviderScope enables Riverpod for the entire application
    const ProviderScope(
      child: RescueMeshApp(),
    ),
  );
}
