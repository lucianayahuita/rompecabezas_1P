import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rompecabezas_app/controller/algorithm_controller.dart';
import 'package:rompecabezas_app/controller/puzzle_controller.dart';
import 'package:rompecabezas_app/models/puzzle_tile.dart';

/// Genera un tablero resuelto y lo mezcla usando solo movimientos válidos
/// (igual que hace PuzzleController internamente), para poder probar el
/// solver sin pasar por la cámara/galería.
List<PuzzleTile> _shuffledSolvedBoard(int gridSize, {int blankIndex = 0}) {
  final tiles = List.generate(
    gridSize * gridSize,
    (i) => PuzzleTile(
      correctIndex: i,
      currentIndex: i,
      imageBytes: i == blankIndex ? Uint8List(0) : Uint8List.fromList([0]),
      isEmpty: i == blankIndex,
    ),
  );

  int fila(int i) => i ~/ gridSize;
  int col(int i) => i % gridSize;
  bool valido(int a, int b) {
    final fa = fila(a), ca = col(a), fb = fila(b), cb = col(b);
    return (ca == cb && (fa - fb).abs() == 1) || (fa == fb && (ca - cb).abs() == 1);
  }

  final random = Random(7);
  for (int i = 0; i < gridSize * gridSize * 40; i++) {
    final emptyIdx = tiles.indexWhere((t) => t.isEmpty);
    final vecinos = [for (int j = 0; j < tiles.length; j++) if (valido(j, emptyIdx)) j];
    final chosen = vecinos[random.nextInt(vecinos.length)];
    final aux = tiles[chosen];
    tiles[chosen] = tiles[emptyIdx];
    tiles[emptyIdx] = aux;
  }

  for (int i = 0; i < tiles.length; i++) {
    tiles[i].currentIndex = i;
  }
  return tiles;
}

void main() {
  test('isSolvable coincide con el teorema de paridad en casos conocidos', () {
    // 3x3 resuelto (0 inversiones) -> solucionable.
    expect(AlgorithmController.isSolvable([0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 8), isTrue);
    // 3x3 con una sola transposición (1 inversión, impar) -> NO solucionable.
    expect(AlgorithmController.isSolvable([1, 0, 2, 3, 4, 5, 6, 7, 8], 3, 8), isFalse);
  });

  test('A* resuelve un 3x3 mezclado', () async {
    final controller = PuzzleController(gridSize: 3, userId: 1);
    controller.tiles = _shuffledSolvedBoard(3, blankIndex: 8);

    final sw = Stopwatch()..start();
    final messages = await AlgorithmController().solveWithAStar(controller);
    sw.stop();

    expect(messages, isEmpty, reason: 'No debería haber mensajes de error/timeout');
    expect(controller.isCompleted, isTrue);
    // ignore: avoid_print
    print('3x3 resuelto en ${sw.elapsedMilliseconds} ms con ${controller.moveCount} movimientos');
  });

  test('A* resuelve un 4x4 mezclado sin colgarse', () async {
    final controller = PuzzleController(gridSize: 4, userId: 1);
    // El blanco NO está en la última posición a propósito, para probar que
    // el solver ya no asume que el vacío es siempre board.length - 1.
    controller.tiles = _shuffledSolvedBoard(4, blankIndex: 5);

    final sw = Stopwatch()..start();
    final messages = await AlgorithmController().solveWithAStar(controller);
    sw.stop();

    expect(messages, isEmpty, reason: 'No debería haber mensajes de error/timeout');
    expect(controller.isCompleted, isTrue);
    // ignore: avoid_print
    print('4x4 resuelto en ${sw.elapsedMilliseconds} ms con ${controller.moveCount} movimientos');

    // Con la implementación vieja (sort() + List.any() en cada paso, sin
    // isolate) esto tardaba muchísimo más o directamente colgaba la app.
    expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
  });
}
