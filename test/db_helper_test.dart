import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rompecabezas_app/controller/puzzle_controller.dart';
import 'package:rompecabezas_app/database/db_helper.dart';
import 'package:rompecabezas_app/models/game_result.dart';
import 'package:rompecabezas_app/models/puzzle_tile.dart';
import 'package:rompecabezas_app/models/user.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('registrar, iniciar sesión, jugar y ver el resultado en el ranking', () async {
    final email = 'test_${DateTime.now().microsecondsSinceEpoch}@ucb.edu.bo';

    final userId = await DBHelper.registerUser(
      User(email: email, password: 'clave123', username: 'tester'),
    );
    expect(userId, greaterThan(0));

    final loggedIn = await DBHelper.loginUser(email, 'clave123');
    expect(loggedIn, isNotNull);
    expect(loggedIn!.id, userId);

    // Simula haber ganado una partida de 3x3.
    await DBHelper.insertResult(GameResult(
      userId: userId,
      level: '3x3',
      moves: 22,
      timeInSeconds: 58,
      date: '2026-09-17 10:00',
    ));

    final stats = await DBHelper.getUserStats(userId);
    expect(stats.partidas, 1);
    expect(stats.mejorTiempo, 58);
    expect(stats.nivelFavorito, '3x3');

    final best = await DBHelper.getBestResultForLevel(userId, '3x3');
    expect(best, isNotNull);
    expect(best!.moves, 22);

    final ranking = await DBHelper.getTopRankingByLevel('3x3');
    expect(ranking.any((row) => row['userId'] == userId), isTrue);

    final weeklyRank = await DBHelper.getUserWeeklyRank(userId);
    expect(weeklyRank, isNotNull);

    final streak = await DBHelper.getStreakDays(userId);
    expect(streak, greaterThanOrEqualTo(0));
  });

  test('ganar una partida DE VERDAD (vía PuzzleController) actualiza las estadísticas', () async {
    final email = 'jugador_${DateTime.now().microsecondsSinceEpoch}@ucb.edu.bo';
    final userId = await DBHelper.registerUser(
      User(email: email, password: 'clave123', username: 'jugador'),
    );

    final controller = PuzzleController(gridSize: 2, userId: userId);
    // Tablero 2x2 ya resuelto salvo una pieza, a un solo movimiento de ganar.
    controller.tiles = [
      PuzzleTile(correctIndex: 0, currentIndex: 0, imageBytes: Uint8List.fromList([0])),
      PuzzleTile(correctIndex: 1, currentIndex: 1, imageBytes: Uint8List.fromList([0])),
      PuzzleTile(correctIndex: 3, currentIndex: 2, imageBytes: Uint8List(0), isEmpty: true),
      PuzzleTile(correctIndex: 2, currentIndex: 3, imageBytes: Uint8List.fromList([0])),
    ];

    // Estado inicial: sin partidas todavía.
    final statsAntes = await DBHelper.getUserStats(userId);
    expect(statsAntes.partidas, 0);

    controller.moveTile(3); // única pieza movible: cae en el hueco y gana.
    expect(controller.isCompleted, isTrue);

    // _saveResult() es fire-and-forget (no se espera dentro de moveTile),
    // así que damos una vuelta al event loop para que termine el insert.
    await Future.delayed(const Duration(milliseconds: 50));

    final statsDespues = await DBHelper.getUserStats(userId);
    expect(statsDespues.partidas, 1, reason: 'La partida jugada no quedó registrada');
    expect(statsDespues.mejorTiempo, isNotNull);

    final best = await DBHelper.getBestResultForLevel(userId, '2x2');
    expect(best, isNotNull);
    expect(best!.moves, controller.moveCount);
  });

  test('no permite registrar el mismo correo dos veces', () async {
    final email = 'dup_${DateTime.now().microsecondsSinceEpoch}@ucb.edu.bo';
    final first = await DBHelper.registerUser(
      User(email: email, password: 'a', username: 'uno'),
    );
    final second = await DBHelper.registerUser(
      User(email: email, password: 'b', username: 'dos'),
    );

    expect(first, greaterThan(0));
    expect(second, -1);
  });
}
