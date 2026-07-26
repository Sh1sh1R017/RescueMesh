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
      version: 2,
      onConfigure: (db) async {
        // WAL mode enables concurrent reads while writing, preventing SQLITE_BUSY
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA synchronous = NORMAL;');
      },
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
        expires_at $_integerType,
        hop_count $_integerType,
        payload $_blobType,
        signature $_textNullable
      )
    ''');

    // B-tree indexes for zero-latency queries during packet bursts
    await db.execute('CREATE INDEX idx_messages_expires_at ON messages(expires_at);');
    await db.execute('CREATE INDEX idx_messages_priority_expires ON messages(priority DESC, expires_at ASC);');

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
    await db.execute('CREATE INDEX idx_reports_category ON reports(category);');

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
    await db.execute('CREATE INDEX idx_sos_status ON sos_requests(status);');

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
    if (oldVersion < 2) {
      // Add expires_at column & indexes if upgrading from v1
      try {
        await db.execute('ALTER TABLE messages ADD COLUMN expires_at INTEGER DEFAULT 0;');
        await db.execute('UPDATE messages SET expires_at = timestamp + ttl WHERE expires_at = 0;');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_expires_at ON messages(expires_at);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_priority_expires ON messages(priority DESC, expires_at ASC);');
      } catch (_) {}
    }
  }

  /// Purges all expired packets from the database to keep disk usage bounded.
  Future<int> purgeExpiredPackets() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.delete(
      'messages',
      where: 'expires_at <= ?',
      whereArgs: [now],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
