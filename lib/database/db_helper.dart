import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/journal_entry.dart';
import '../models/nlp_result.dart';
import '../models/assessment.dart';
import '../models/chat_session.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mental_health.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users (
        userID INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE JournalEntry (
        entryID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        text TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (userID) REFERENCES Users (userID) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE NLPResults (
        resultID INTEGER PRIMARY KEY AUTOINCREMENT,
        entryID INTEGER NOT NULL,
        emotion TEXT NOT NULL,
        confidence REAL NOT NULL,
        FOREIGN KEY (entryID) REFERENCES JournalEntry (entryID) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Assessment (
        assessID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        scaleType TEXT NOT NULL,
        score INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (userID) REFERENCES Users (userID) ON DELETE CASCADE
      )
    ''');

    await _createChatTables(db);
    await _createNewFeatureTables(db);
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE ChatSessions (
        sessionID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        startedAt TEXT NOT NULL,
        lastMessageAt TEXT,
        preview TEXT,
        FOREIGN KEY (userID) REFERENCES Users (userID) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ChatMessages (
        messageID INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionID INTEGER NOT NULL,
        isUser INTEGER NOT NULL,
        text TEXT NOT NULL,
        sentAt TEXT NOT NULL,
        emotion TEXT,
        confidence REAL,
        FOREIGN KEY (sessionID) REFERENCES ChatSessions (sessionID) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createNewFeatureTables(Database db) async {
    // Daily mood check-in (quick one-tap mood)
    await db.execute('''
      CREATE TABLE DailyCheckIn (
        checkInID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        mood TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (userID) REFERENCES Users (userID) ON DELETE CASCADE
      )
    ''');

    // Exercise completion log
    await db.execute('''
      CREATE TABLE ExerciseLog (
        logID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        exerciseType TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        FOREIGN KEY (userID) REFERENCES Users (userID) ON DELETE CASCADE
      )
    ''');

    // User streaks
    await db.execute('''
      CREATE TABLE UserStreaks (
        streakID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER UNIQUE NOT NULL,
        currentStreak INTEGER NOT NULL DEFAULT 0,
        longestStreak INTEGER NOT NULL DEFAULT 0,
        lastActiveDate TEXT,
        FOREIGN KEY (userID) REFERENCES Users (userID) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createChatTables(db);
    }
    if (oldVersion < 3) {
      // Add confidence column to existing ChatMessages table
      try {
        await db.execute('ALTER TABLE ChatMessages ADD COLUMN confidence REAL');
      } catch (_) {
        // Column may already exist if table was freshly created
      }
    }
    if (oldVersion < 4) {
      await _createNewFeatureTables(db);
    }
  }

  // --- Daily Check-In ---
  Future<void> createDailyCheckIn(int userID, String mood) async {
    final db = await instance.database;
    await db.insert('DailyCheckIn', {
      'userID': userID,
      'mood': mood,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getTodayCheckIn(int userID) async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.query(
      'DailyCheckIn',
      where: 'userID = ? AND date LIKE ?',
      whereArgs: [userID, '$today%'],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first['mood'] as String;
    return null;
  }

  Future<List<Map<String, dynamic>>> getWeeklyCheckIns(int userID) async {
    final db = await instance.database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    return await db.query(
      'DailyCheckIn',
      where: 'userID = ? AND date >= ?',
      whereArgs: [userID, weekAgo],
      orderBy: 'date ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlyCheckIns(int userID) async {
    final db = await instance.database;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    return await db.query(
      'DailyCheckIn',
      where: 'userID = ? AND date >= ?',
      whereArgs: [userID, monthAgo],
      orderBy: 'date ASC',
    );
  }

  // --- Exercise Log ---
  Future<void> logExercise(int userID, String exerciseType, int durationSeconds) async {
    final db = await instance.database;
    await db.insert('ExerciseLog', {
      'userID': userID,
      'exerciseType': exerciseType,
      'durationSeconds': durationSeconds,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserExercises(int userID, {int limit = 20}) async {
    final db = await instance.database;
    return await db.query(
      'ExerciseLog',
      where: 'userID = ?',
      whereArgs: [userID],
      orderBy: 'completedAt DESC',
      limit: limit,
    );
  }

  Future<int> getExerciseCount(int userID) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ExerciseLog WHERE userID = ?',
      [userID],
    );
    return result.first['count'] as int;
  }

  // --- Streaks ---
  Future<Map<String, int>> getUserStreak(int userID) async {
    final db = await instance.database;
    final result = await db.query(
      'UserStreaks',
      where: 'userID = ?',
      whereArgs: [userID],
    );
    if (result.isEmpty) {
      return {'currentStreak': 0, 'longestStreak': 0};
    }
    return {
      'currentStreak': result.first['currentStreak'] as int,
      'longestStreak': result.first['longestStreak'] as int,
    };
  }

  Future<void> updateStreak(int userID) async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final existing = await db.query(
      'UserStreaks',
      where: 'userID = ?',
      whereArgs: [userID],
    );

    if (existing.isEmpty) {
      await db.insert('UserStreaks', {
        'userID': userID,
        'currentStreak': 1,
        'longestStreak': 1,
        'lastActiveDate': today,
      });
      return;
    }

    final lastDate = existing.first['lastActiveDate'] as String?;
    int current = existing.first['currentStreak'] as int;
    int longest = existing.first['longestStreak'] as int;

    if (lastDate == today) return; // Already active today

    final yesterday = DateTime.now().subtract(const Duration(days: 1))
        .toIso8601String().substring(0, 10);

    if (lastDate == yesterday) {
      current += 1;
    } else {
      current = 1;
    }
    if (current > longest) longest = current;

    await db.update(
      'UserStreaks',
      {
        'currentStreak': current,
        'longestStreak': longest,
        'lastActiveDate': today,
      },
      where: 'userID = ?',
      whereArgs: [userID],
    );
  }

  // --- Weekly Summary ---
  Future<Map<String, dynamic>> getWeeklySummary(int userID) async {
    final db = await instance.database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    // Journal entries this week
    final journals = await db.rawQuery(
      'SELECT COUNT(*) as count FROM JournalEntry WHERE userID = ? AND date >= ?',
      [userID, weekAgo],
    );

    // Chat messages this week
    final chats = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ChatMessages m
      INNER JOIN ChatSessions s ON m.sessionID = s.sessionID
      WHERE s.userID = ? AND m.sentAt >= ? AND m.isUser = 1
    ''', [userID, weekAgo]);

    // Assessments this week
    final assessments = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Assessment WHERE userID = ? AND date >= ?',
      [userID, weekAgo],
    );

    // Exercises this week
    final exercises = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ExerciseLog WHERE userID = ? AND completedAt >= ?',
      [userID, weekAgo],
    );

    // Check-ins this week
    final checkIns = await db.rawQuery(
      'SELECT COUNT(*) as count FROM DailyCheckIn WHERE userID = ? AND date >= ?',
      [userID, weekAgo],
    );

    // Emotion distribution from chat this week
    final emotions = await db.rawQuery('''
      SELECT m.emotion, COUNT(*) as count FROM ChatMessages m
      INNER JOIN ChatSessions s ON m.sessionID = s.sessionID
      WHERE s.userID = ? AND m.sentAt >= ? AND m.isUser = 0
        AND m.emotion IS NOT NULL AND m.emotion != ''
      GROUP BY m.emotion
      ORDER BY count DESC
    ''', [userID, weekAgo]);

    return {
      'journalCount': journals.first['count'] as int,
      'chatCount': chats.first['count'] as int,
      'assessmentCount': assessments.first['count'] as int,
      'exerciseCount': exercises.first['count'] as int,
      'checkInCount': checkIns.first['count'] as int,
      'emotions': emotions,
    };
  }

  // --- Chat Sessions ---
  Future<ChatSession> createChatSession(ChatSession session) async {
    final db = await instance.database;
    final id = await db.insert('ChatSessions', session.toMap()..remove('sessionID'));
    return session.copyWith(sessionID: id);
  }

  Future<void> updateChatSession(int sessionID, {String? lastMessageAt, String? preview}) async {
    final db = await instance.database;
    final updates = <String, dynamic>{};
    if (lastMessageAt != null) updates['lastMessageAt'] = lastMessageAt;
    if (preview != null) updates['preview'] = preview;
    if (updates.isEmpty) return;
    await db.update('ChatSessions', updates, where: 'sessionID = ?', whereArgs: [sessionID]);
  }

  Future<List<ChatSession>> getUserChatSessions(int userID) async {
    final db = await instance.database;
    final maps = await db.query(
      'ChatSessions',
      where: 'userID = ?',
      whereArgs: [userID],
      orderBy: 'lastMessageAt DESC, startedAt DESC',
    );
    return maps.map((m) => ChatSession.fromMap(m)).toList();
  }

  Future<void> deleteChatSession(int sessionID) async {
    final db = await instance.database;
    await db.delete('ChatSessions', where: 'sessionID = ?', whereArgs: [sessionID]);
  }

  // --- Chat Messages ---
  Future<ChatMessageRecord> createChatMessage(ChatMessageRecord message) async {
    final db = await instance.database;
    final map = message.toMap()..remove('messageID');
    final id = await db.insert('ChatMessages', map);
    return ChatMessageRecord(
      messageID: id,
      sessionID: message.sessionID,
      isUser: message.isUser,
      text: message.text,
      sentAt: message.sentAt,
      emotion: message.emotion,
      confidence: message.confidence,
    );
  }

  Future<List<ChatMessageRecord>> getSessionMessages(int sessionID) async {
    final db = await instance.database;
    final maps = await db.query(
      'ChatMessages',
      where: 'sessionID = ?',
      whereArgs: [sessionID],
      orderBy: 'sentAt ASC',
    );
    return maps.map((m) => ChatMessageRecord.fromMap(m)).toList();
  }

  /// Get emotions detected from chat messages for a specific user.
  /// Returns NLPResult-like data from the ChatMessages table.
  Future<List<NLPResult>> getUserChatEmotions(int userID) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT m.messageID AS resultID, m.sessionID AS entryID,
             m.emotion, m.confidence, m.sentAt
      FROM ChatMessages m
      INNER JOIN ChatSessions s ON m.sessionID = s.sessionID
      WHERE s.userID = ? AND m.isUser = 0 AND m.emotion IS NOT NULL AND m.emotion != ''
      ORDER BY m.sentAt ASC
    ''', [userID]);

    return result.map((map) => NLPResult(
      resultID: map['resultID'] as int?,
      entryID: map['entryID'] as int,
      emotion: _mapChatEmotionToCategory(map['emotion'] as String),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.70,
    )).toList();
  }

  /// Maps diagnostic labels from the AI to the mood tracker categories.
  String _mapChatEmotionToCategory(String rawEmotion) {
    final lower = rawEmotion.toLowerCase();
    if (lower.contains('stress')) return 'Anxiety';
    if (lower.contains('anxiety')) return 'Anxiety';
    if (lower.contains('depression')) return 'Sadness';
    if (lower.contains('bipolar')) return 'Anxiety';
    if (lower.contains('personality')) return 'Anxiety';
    if (lower.contains('positive') || lower.contains('normal / positive')) return 'Joy';
    if (lower.contains('mixed')) return 'Anxiety';
    return 'Neutral';
  }

  // --- Users ---
  Future<User> createUser(User user) async {
    final db = await instance.database;
    final id = await db.insert('Users', user.toMap());
    return User(
      userID: id,
      name: user.name,
      email: user.email,
      password: user.password,
    );
  }

  Future<User?> getUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'Users',
      columns: ['userID', 'name', 'email', 'password'],
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query('Users', where: 'userID = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // --- Journal Entries ---
  Future<JournalEntry> createJournalEntry(JournalEntry entry) async {
    final db = await instance.database;
    final id = await db.insert('JournalEntry', entry.toMap());
    return JournalEntry(
      entryID: id,
      userID: entry.userID,
      text: entry.text,
      date: entry.date,
    );
  }

  Future<List<JournalEntry>> getUserJournalEntries(int userID) async {
    final db = await instance.database;
    final maps = await db.query(
      'JournalEntry',
      where: 'userID = ?',
      whereArgs: [userID],
      orderBy: 'date DESC',
    );
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  // --- NLP Results ---
  Future<NLPResult> createNLPResult(NLPResult result) async {
    final db = await instance.database;
    final id = await db.insert('NLPResults', result.toMap());
    return NLPResult(
      resultID: id,
      entryID: result.entryID,
      emotion: result.emotion,
      confidence: result.confidence,
    );
  }

  Future<List<NLPResult>> getUserEmotions(int userID) async {
    final db = await instance.database;
    // Join with JournalEntry to get user's results
    final result = await db.rawQuery('''
      SELECT n.* FROM NLPResults n
      INNER JOIN JournalEntry j ON n.entryID = j.entryID
      WHERE j.userID = ?
      ORDER BY j.date ASC
    ''', [userID]);
    
    return result.map((map) => NLPResult.fromMap(map)).toList();
  }

  // --- Assessments ---
  Future<Assessment> createAssessment(Assessment assessment) async {
    final db = await instance.database;
    final id = await db.insert('Assessment', assessment.toMap());
    return Assessment(
      assessID: id,
      userID: assessment.userID,
      scaleType: assessment.scaleType,
      score: assessment.score,
      date: assessment.date,
    );
  }

  Future<List<Assessment>> getUserAssessments(int userID) async {
    final db = await instance.database;
    final maps = await db.query(
      'Assessment',
      where: 'userID = ?',
      whereArgs: [userID],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Assessment.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
