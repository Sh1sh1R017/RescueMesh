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
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const blobType = 'BLOB';

    // Nodes Table
    await db.execute('''
      CREATE TABLE nodes (
        id $idType,
        last_seen $integerType,
        public_key $textNullable
      )
    ''');

    // Messages Table (Core Mesh Store-and-Forward)
    await db.execute('''
      CREATE TABLE messages (
        msg_id $idType,
        origin_node_id $textType,
        type $integerType,
        priority $integerType,
        timestamp $integerType,
        ttl $integerType,
        hop_count $integerType,
        payload $blobType,
        signature $textNullable
      )
    ''');

    // Reports Table (Parsed Map Data)
    await db.execute('''
      CREATE TABLE reports (
        uuid $idType,
        lat $realType,
        lng $realType,
        category $textType,
        severity $integerType,
        description $textNullable,
        verification_score $integerType
      )
    ''');

    // SOS Requests Table
    await db.execute('''
      CREATE TABLE sos_requests (
        uuid $idType,
        type $textType,
        status $textType
      )
    ''');

    // Missing Persons Table
    await db.execute('''
      CREATE TABLE missing_persons (
        uuid $idType,
        name $textType,
        last_known_lat $realType,
        last_known_lng $realType,
        description $textNullable,
        status $textType
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
