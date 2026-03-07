import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static const String _dbName = 'medreminder.db';
  static const int _dbVersion = 1;
  static const String _keyName = 'db_encryption_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> _getOrCreateEncryptionKey() async {
    String? key = await _secureStorage.read(key: _keyName);
    if (key == null) {
      key = const Uuid().v4() + const Uuid().v4(); // 32字符密钥
      await _secureStorage.write(key: _keyName, value: key);
    }
    return key;
  }

  Future<Database> _initDatabase() async {
    String encryptionKey = await _getOrCreateEncryptionKey();
    String path = await getDatabasesPath() + '/' + _dbName;

    return await openDatabase(
      path,
      version: _dbVersion,
      password: encryptionKey,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 药品/保健品表
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        dosage TEXT NOT NULL,
        usage TEXT,
        schedule TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        stopped_at TEXT,
        plan_group_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 服药记录表
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        actual_time TEXT,
        status TEXT NOT NULL,
        skip_reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // 设置表
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // 初始化默认设置
    await _initDefaultSettings(db);
  }

  Future<void> _initDefaultSettings(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultSettings = {
      'voice_enabled': 'true',
      'voice_medicine_enabled': 'true',
      'voice_supplement_enabled': 'true',
      'large_text_mode': 'false',
      'has_agreed_privacy': 'false',
      'device_uuid': const Uuid().v4(),
    };

    for (var entry in defaultSettings.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value,
        'updated_at': now,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时执行
  }

  // Medication CRUD
  Future<int> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;
    return await db.insert('medications', medication);
  }

  Future<List<Map<String, dynamic>>> getMedications({
    bool? isActive,
    String? searchQuery,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (isActive != null) {
      where = 'is_active = ?';
      whereArgs = [isActive ? 1 : 0];
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (where.isNotEmpty) {
        where += ' AND ';
      }
      where += 'name LIKE ?';
      whereArgs.add('%$searchQuery%');
    }

    return await db.query(
      'medications',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getMedicationById(String id) async {
    final db = await database;
    final results = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateMedication(String id, Map<String, dynamic> medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Record CRUD
  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('records', record);
  }

  Future<List<Map<String, dynamic>>> getRecords({
    String? medicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (medicationId != null) {
      where = 'medication_id = ?';
      whereArgs = [medicationId];
    }

    if (startDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'scheduled_time >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'scheduled_time <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'records',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'scheduled_time DESC',
    );
  }

  Future<Map<String, dynamic>?> getRecordById(String id) async {
    final db = await database;
    final results = await db.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateRecord(String id, Map<String, dynamic> record) async {
    final db = await database;
    return await db.update(
      'records',
      record,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRecord(String id) async {
    final db = await database;
    return await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  Future<int> setSetting(String key, dynamic value) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert(
      'settings',
      {'key': key, 'value': value.toString(), 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final results = await db.query('settings');
    return Map.fromEntries(
      results.map((r) => MapEntry(r['key'] as String, r['value'] as String)),
    );
  }

  // 统计
  Future<Map<String, int>> getRecordStats(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM records
      WHERE scheduled_time >= ? AND scheduled_time < ?
      GROUP BY status
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    Map<String, int> stats = {'total': 0, 'taken': 0, 'skipped': 0, 'missed': 0};
    for (var row in result) {
      String status = row['status'] as String;
      int count = row['count'] as int;
      stats[status] = count;
      stats['total'] = (stats['total'] ?? 0) + count;
    }
    return stats;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}