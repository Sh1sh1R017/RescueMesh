import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rescuemesh.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  static const String _idType = 'TEXT PRIMARY KEY';
  static const String _textType = 'TEXT NOT NULL';
  static const String _textNullable = 'TEXT';
  static const String _integerType = 'INTEGER NOT NULL';
  static const String _realType = 'REAL NOT NULL';
  static const String _blobType = 'BLOB';

  Future<void> _createDB(Database db, int version) async {
    // Nodes Table
    await db.execute('''
      CREATE TABLE nodes (
        id $_idType,
        last_seen $_integerType,
        public_key $_textNullable
      )
    ''');

    // Messages Table (Core Mesh Store-and-Forward)
    await db.execute('''
      CREATE TABLE messages (
        msg_id $_idType,
        origin_node_id $_textType,
        type $_integerType,
        priority $_integerType,
        timestamp $_integerType,
        ttl $_integerType,
        hop_count $_integerType,
        payload $_blobType,
        signature $_textNullable
      )
    ''');

    // Reports Table (Parsed Map Data)
    await db.execute('''
      CREATE TABLE reports (
        uuid $_idType,
        lat $_realType,
        lng $_realType,
        category $_textType,
        severity $_integerType,
        description $_textNullable,
        verification_score $_integerType
      )
    ''');

    // SOS Requests Table
    await db.execute('''
      CREATE TABLE sos_requests (
        uuid $_idType,
        origin_node_id $_textType,
        type $_textType,
        status $_textType,
        timestamp $_integerType
      )
    ''');

    // Missing Persons Table
    await db.execute('''
      CREATE TABLE missing_persons (
        uuid $_idType,
        name $_textType,
        last_known_lat $_realType,
        last_known_lng $_realType,
        description $_textNullable,
        status $_textType
      )
    ''');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    // Schema migration hook for future versions
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
