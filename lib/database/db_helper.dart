import 'package:flutter/foundation.dart'; // Importante para detectar kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game_result.dart';
import '../models/user.dart';

class DBHelper {
  static Database? _db;
  static const String _tableResults = 'results';
  static const String _tableUsers = 'users';

  // Almacenamiento temporal en memoria solo para pruebas en Chrome (Web)
  static final List<User> _mockWebUsers = [];
  static final List<GameResult> _mockWebResults = [];

  static Future<Database?> get database async {
    if (kIsWeb) return null; // Evita inicializar SQLite si estamos en Chrome
    
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'puzzle_game.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Tabla de Usuarios
        await db.execute('''
          CREATE TABLE $_tableUsers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            username TEXT
          )
        ''');

        // 2. Tabla de Resultados (vinculada con userId)
        await db.execute('''
          CREATE TABLE $_tableResults (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            level TEXT NOT NULL,
            moves INTEGER NOT NULL,
            timeInSeconds INTEGER NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES $_tableUsers (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ==========================================
  // QUERYS DE AUTENTICACIÓN (LOGIN Y REGISTRO)
  // ==========================================

  // REGISTRO: Crear un nuevo usuario
  static Future<int> registerUser(User user) async {
    if (kIsWeb) {
      // Simulación para Web
      bool exists = _mockWebUsers.any((u) => u.email == user.email);
      if (exists) return -1;
      
      final newUser = User(
        id: _mockWebUsers.length + 1,
        email: user.email,
        password: user.password,
        username: user.username,
      );
      _mockWebUsers.add(newUser);
      return newUser.id!;
    }

    final db = await database;
    try {
      return await db!.insert(
        _tableUsers,
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      return -1;
    }
  }

  // LOGIN: Verificar credenciales de correo y contraseña
  static Future<User?> loginUser(String email, String password) async {
    if (kIsWeb) {
      // Simulación para Web
      try {
        return _mockWebUsers.firstWhere(
          (u) => u.email == email && u.password == password,
        );
      } catch (e) {
        return null;
      }
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      _tableUsers,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // COMPROBAR EXISTENCIA: Verificar si un email ya está registrado
  static Future<bool> isEmailRegistered(String email) async {
    if (kIsWeb) {
      return _mockWebUsers.any((u) => u.email == email);
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      _tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  // ==========================================
  // QUERYS DE RESULTADOS Y RANKING
  // ==========================================

  // Insertar un nuevo resultado
  static Future<int> insertResult(GameResult result) async {
    if (kIsWeb) {
      _mockWebResults.add(result);
      return _mockWebResults.length;
    }

    final db = await database;
    return await db!.insert(
      _tableResults,
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener Ranking por Nivel
  static Future<List<Map<String, dynamic>>> getTopRankingByLevel(String level) async {
    if (kIsWeb) {
      return _mockWebResults
          .where((r) => r.level == level)
          .map((r) => {
                'id': r.id ?? 1,
                'userId': r.userId,
                'moves': r.moves,
                'timeInSeconds': r.timeInSeconds,
                'date': r.date,
                'level': r.level,
                'email': 'jugador_web@gmail.com',
                'username': 'Jugador Web',
              })
          .toList();
    }

    final db = await database;
    return await db!.rawQuery('''
      SELECT r.id, r.userId, r.moves, r.timeInSeconds, r.date, r.level, u.email, u.username
      FROM $_tableResults r
      INNER JOIN $_tableUsers u ON r.userId = u.id
      WHERE r.level = ?
      ORDER BY r.moves ASC, r.timeInSeconds ASC
      LIMIT 10
    ''', [level]);
  }

  // Historial del Usuario
  static Future<List<GameResult>> getUserHistory(int userId) async {
    if (kIsWeb) {
      return _mockWebResults.where((r) => r.userId == userId).toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      _tableResults,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => GameResult.fromMap(map)).toList();
  }

  // ==========================================
  // QUERYS DEL DASHBOARD (ESTADÍSTICAS, RACHA, RANKING SEMANAL)
  // ==========================================

  /// Partidas jugadas y mejor tiempo global de un usuario.
  static Future<({int partidas, int? mejorTiempo, String? nivelFavorito})> getUserStats(
    int userId,
  ) async {
    final history = await getUserHistory(userId);

    if (history.isEmpty) {
      return (partidas: 0, mejorTiempo: null, nivelFavorito: null);
    }

    final int mejorTiempo =
        history.map((r) => r.timeInSeconds).reduce((a, b) => a < b ? a : b);

    final Map<String, int> conteoPorNivel = {};
    for (final r in history) {
      conteoPorNivel[r.level] = (conteoPorNivel[r.level] ?? 0) + 1;
    }
    final String nivelFavorito =
        conteoPorNivel.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return (
      partidas: history.length,
      mejorTiempo: mejorTiempo,
      nivelFavorito: nivelFavorito,
    );
  }

  /// El mejor resultado (menor tiempo) de un usuario para un nivel puntual.
  static Future<GameResult?> getBestResultForLevel(int userId, String level) async {
    if (kIsWeb) {
      final candidatos =
          _mockWebResults.where((r) => r.userId == userId && r.level == level).toList();
      if (candidatos.isEmpty) return null;
      candidatos.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));
      return candidatos.first;
    }

    final db = await database;
    final maps = await db!.query(
      _tableResults,
      where: 'userId = ? AND level = ?',
      whereArgs: [userId, level],
      orderBy: 'timeInSeconds ASC, moves ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GameResult.fromMap(maps.first);
  }

  /// Racha de días consecutivos (incluyendo hoy o ayer) con al menos una
  /// partida completada.
  static Future<int> getStreakDays(int userId) async {
    final history = await getUserHistory(userId);
    if (history.isEmpty) return 0;

    final Set<String> diasConPartida =
        history.map((r) => r.date.substring(0, 10)).toSet();

    DateTime cursor = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Si hoy todavía no jugó, la racha se cuenta desde ayer hacia atrás.
    if (!diasConPartida.contains(fmt(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!diasConPartida.contains(fmt(cursor))) return 0;
    }

    int racha = 0;
    while (diasConPartida.contains(fmt(cursor))) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return racha;
  }

  /// Mejor tiempo por jugador en los últimos 7 días, para el mini-ranking
  /// semanal del dashboard.
  static Future<List<Map<String, dynamic>>> getWeeklyTop({int limit = 50}) async {
    final DateTime hace7Dias = DateTime.now().subtract(const Duration(days: 7));
    final String corte =
        '${hace7Dias.year}-${hace7Dias.month.toString().padLeft(2, '0')}-${hace7Dias.day.toString().padLeft(2, '0')}';

    if (kIsWeb) {
      final Map<int, Map<String, dynamic>> mejorPorUsuario = {};
      for (final r in _mockWebResults) {
        if (r.date.compareTo(corte) < 0) continue;
        final actual = mejorPorUsuario[r.userId];
        if (actual == null || r.timeInSeconds < (actual['timeInSeconds'] as int)) {
          mejorPorUsuario[r.userId] = {
            'userId': r.userId,
            'timeInSeconds': r.timeInSeconds,
            'username': 'Jugador Web',
          };
        }
      }
      final list = mejorPorUsuario.values.toList()
        ..sort((a, b) =>
            (a['timeInSeconds'] as int).compareTo(b['timeInSeconds'] as int));
      return list.take(limit).toList();
    }

    final db = await database;
    return await db!.rawQuery('''
      SELECT u.id as userId, u.username, u.email, MIN(r.timeInSeconds) as timeInSeconds
      FROM $_tableResults r
      INNER JOIN $_tableUsers u ON r.userId = u.id
      WHERE r.date >= ?
      GROUP BY r.userId
      ORDER BY timeInSeconds ASC
      LIMIT ?
    ''', [corte, limit]);
  }

  /// Posición (1-indexed) de un usuario dentro del ranking semanal, o null si
  /// todavía no tiene resultados en los últimos 7 días.
  static Future<int?> getUserWeeklyRank(int userId) async {
    final top = await getWeeklyTop(limit: 1000);
    final index = top.indexWhere((row) => row['userId'] == userId);
    return index == -1 ? null : index + 1;
  }
}