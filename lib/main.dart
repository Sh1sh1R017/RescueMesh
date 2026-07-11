import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/app.dart';
import 'data/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database
  await AppDatabase.instance.database;
  
  runApp(
    // ProviderScope enables Riverpod for the entire application
    const ProviderScope(
      child: RescueMeshApp(),
    ),
  );
}
