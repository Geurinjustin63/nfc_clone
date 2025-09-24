import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../models/nfc_card.dart';
import '../models/user_session.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Cards table
    await db.execute('''
      CREATE TABLE ${AppConstants.cardsTableName}(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        raw_data TEXT NOT NULL,
        uid TEXT NOT NULL,
        standard TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tags TEXT,
        read_count INTEGER DEFAULT 0,
        is_cloned INTEGER DEFAULT 0,
        source_card_id TEXT,
        metadata TEXT
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE ${AppConstants.sessionsTableName}(
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_access_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        device_id TEXT NOT NULL,
        device_info TEXT NOT NULL,
        failed_attempts INTEGER DEFAULT 0,
        metadata TEXT
      )
    ''');

    // Tags table for card tagging system
    await db.execute('''
      CREATE TABLE ${AppConstants.tagsTableName}(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created_at TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_cards_type ON ${AppConstants.cardsTableName}(type)');
    await db.execute('CREATE INDEX idx_cards_status ON ${AppConstants.cardsTableName}(status)');
    await db.execute('CREATE INDEX idx_cards_created_at ON ${AppConstants.cardsTableName}(created_at)');
    await db.execute('CREATE INDEX idx_sessions_status ON ${AppConstants.sessionsTableName}(status)');
    await db.execute('CREATE INDEX idx_sessions_expires_at ON ${AppConstants.sessionsTableName}(expires_at)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add any new columns or tables for version 2
    }
  }

  // Card operations
  Future<String> insertCard(NFCCard card) async {
    final db = await database;
    final cardMap = card.toMap();
    
    // Convert complex data types to JSON strings
    cardMap['raw_data'] = jsonEncode(cardMap['raw_data']);
    cardMap['uid'] = jsonEncode(cardMap['uid']);
    cardMap['tags'] = jsonEncode(cardMap['tags']);
    cardMap['metadata'] = jsonEncode(cardMap['metadata']);
    
    await db.insert(AppConstants.cardsTableName, cardMap);
    return card.id;
  }

  Future<NFCCard?> getCard(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.cardsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToCard(maps.first);
    }
    return null;
  }

  Future<List<NFCCard>> getAllCards({
    CardStatus? status,
    CardType? type,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null) {
      whereClause += 'status = ?';
      whereArgs.add(status.index);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.index);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(name LIKE ? OR description LIKE ?)';
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.cardsTableName,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToCard(map)).toList();
  }

  Future<int> updateCard(NFCCard card) async {
    final db = await database;
    final cardMap = card.toMap();
    
    // Convert complex data types to JSON strings
    cardMap['raw_data'] = jsonEncode(cardMap['raw_data']);
    cardMap['uid'] = jsonEncode(cardMap['uid']);
    cardMap['tags'] = jsonEncode(cardMap['tags']);
    cardMap['metadata'] = jsonEncode(cardMap['metadata']);

    return await db.update(
      AppConstants.cardsTableName,
      cardMap,
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(String id) async {
    final db = await database;
    return await db.delete(
      AppConstants.cardsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCardsCount({CardStatus? status, CardType? type}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null) {
      whereClause = 'status = ?';
      whereArgs.add(status.index);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.index);
    }

    final result = await db.query(
      AppConstants.cardsTableName,
      columns: ['COUNT(*) as count'],
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<NFCCard>> getFavoriteCards() async {
    return await getAllCards(status: CardStatus.favorite);
  }

  Future<List<NFCCard>> getRecentCards({int limit = 10}) async {
    return await getAllCards(limit: limit);
  }

  // Session operations
  Future<String> insertSession(UserSession session) async {
    final db = await database;
    final sessionMap = session.toMap();
    sessionMap['metadata'] = jsonEncode(sessionMap['metadata']);
    
    await db.insert(AppConstants.sessionsTableName, sessionMap);
    return session.id;
  }

  Future<UserSession?> getActiveSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.sessionsTableName,
      where: 'status = ? AND expires_at > ?',
      whereArgs: [SessionStatus.active.index, DateTime.now().toIso8601String()],
      orderBy: 'last_access_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _mapToSession(maps.first);
    }
    return null;
  }

  Future<int> updateSession(UserSession session) async {
    final db = await database;
    final sessionMap = session.toMap();
    sessionMap['metadata'] = jsonEncode(sessionMap['metadata']);

    return await db.update(
      AppConstants.sessionsTableName,
      sessionMap,
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> expireAllSessions() async {
    final db = await database;
    return await db.update(
      AppConstants.sessionsTableName,
      {'status': SessionStatus.expired.index},
      where: 'status = ?',
      whereArgs: [SessionStatus.active.index],
    );
  }

  // Analytics operations
  Future<Map<String, int>> getCardTypeDistribution() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT type, COUNT(*) as count 
      FROM ${AppConstants.cardsTableName} 
      WHERE status != ? 
      GROUP BY type
    ''', [CardStatus.archived.index]);

    Map<String, int> distribution = {};
    for (var row in result) {
      final cardType = CardType.values[row['type'] as int];
      distribution[cardType.name] = row['count'] as int;
    }
    return distribution;
  }

  Future<Map<String, int>> getCardsByMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', created_at) as month, COUNT(*) as count
      FROM ${AppConstants.cardsTableName}
      WHERE status != ?
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY month DESC
      LIMIT 12
    ''', [CardStatus.archived.index]);

    Map<String, int> monthlyData = {};
    for (var row in result) {
      monthlyData[row['month'] as String] = row['count'] as int;
    }
    return monthlyData;
  }

  // Helper methods
  NFCCard _mapToCard(Map<String, dynamic> map) {
    final cardMap = Map<String, dynamic>.from(map);
    
    // Parse JSON strings back to objects
    cardMap['raw_data'] = jsonDecode(cardMap['raw_data']);
    cardMap['uid'] = List<int>.from(jsonDecode(cardMap['uid']));
    cardMap['tags'] = List<String>.from(jsonDecode(cardMap['tags'] ?? '[]'));
    cardMap['metadata'] = Map<String, dynamic>.from(jsonDecode(cardMap['metadata'] ?? '{}'));
    
    return NFCCard.fromMap(cardMap);
  }

  UserSession _mapToSession(Map<String, dynamic> map) {
    final sessionMap = Map<String, dynamic>.from(map);
    sessionMap['metadata'] = Map<String, dynamic>.from(jsonDecode(sessionMap['metadata'] ?? '{}'));
    
    return UserSession.fromMap(sessionMap);
  }

  // Database maintenance
  Future<void> cleanupExpiredSessions() async {
    final db = await database;
    await db.delete(
      AppConstants.sessionsTableName,
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().subtract(const Duration(days: 30)).toIso8601String()],
    );
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}