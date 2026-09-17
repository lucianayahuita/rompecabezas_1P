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
      SELECT r.id, r.moves, r.timeInSeconds, r.date, r.level, u.email, u.username
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
}