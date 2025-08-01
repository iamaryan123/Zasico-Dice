// models/ludo_board_data.dart
import 'dart:ui';

class LudoBoardData {
  static const double boardSize = 400.0;
  static const double cellSize = boardSize / 15;

  // Board path positions for each color
  static const List<List<int>> colorPaths = [
    // Red path (starts from position 1)
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52],
    // Blue path (starts from position 14)
    [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
    // Yellow path (starts from position 27)
    [27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
    // Green path (starts from position 40)
    [40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39],
  ];

  // Safe positions on the board
  static const List<int> safePositions = [1, 9, 14, 22, 27, 35, 40, 48];

  // Home positions for each color
  static const Map<String, List<Offset>> homePositions = {
    'red': [
      Offset(1.5 * cellSize, 1.5 * cellSize),
      Offset(3.5 * cellSize, 1.5 * cellSize),
      Offset(1.5 * cellSize, 3.5 * cellSize),
      Offset(3.5 * cellSize, 3.5 * cellSize),
    ],
    'blue': [
      Offset(10.5 * cellSize, 1.5 * cellSize),
      Offset(12.5 * cellSize, 1.5 * cellSize),
      Offset(10.5 * cellSize, 3.5 * cellSize),
      Offset(12.5 * cellSize, 3.5 * cellSize),
    ],
    'yellow': [
      Offset(10.5 * cellSize, 10.5 * cellSize),
      Offset(12.5 * cellSize, 10.5 * cellSize),
      Offset(10.5 * cellSize, 12.5 * cellSize),
      Offset(12.5 * cellSize, 12.5 * cellSize),
    ],
    'green': [
      Offset(1.5 * cellSize, 10.5 * cellSize),
      Offset(3.5 * cellSize, 10.5 * cellSize),
      Offset(1.5 * cellSize, 12.5 * cellSize),
      Offset(3.5 * cellSize, 12.5 * cellSize),
    ],
  };

  // Track positions on the board
  static final List<Offset> trackPositions = [
    // Main track positions (52 positions total)
    Offset(6 * cellSize, 13 * cellSize), // 1
    Offset(6 * cellSize, 12 * cellSize), // 2
    Offset(6 * cellSize, 11 * cellSize), // 3
    Offset(6 * cellSize, 10 * cellSize), // 4
    Offset(6 * cellSize, 9 * cellSize),  // 5
    Offset(5 * cellSize, 9 * cellSize),  // 6
    Offset(4 * cellSize, 9 * cellSize),  // 7
    Offset(3 * cellSize, 9 * cellSize),  // 8
    Offset(2 * cellSize, 9 * cellSize),  // 9 (safe)
    Offset(1 * cellSize, 9 * cellSize),  // 10
    Offset(0 * cellSize, 9 * cellSize),  // 11
    Offset(0 * cellSize, 8 * cellSize),  // 12
    Offset(0 * cellSize, 7 * cellSize),  // 13
    Offset(1 * cellSize, 6 * cellSize),  // 14 (safe)
    Offset(2 * cellSize, 6 * cellSize),  // 15
    Offset(3 * cellSize, 6 * cellSize),  // 16
    Offset(4 * cellSize, 6 * cellSize),  // 17
    Offset(5 * cellSize, 6 * cellSize),  // 18
    Offset(6 * cellSize, 5 * cellSize),  // 19
    Offset(6 * cellSize, 4 * cellSize),  // 20
    Offset(6 * cellSize, 3 * cellSize),  // 21
    Offset(6 * cellSize, 2 * cellSize),  // 22 (safe)
    Offset(6 * cellSize, 1 * cellSize),  // 23
    Offset(6 * cellSize, 0 * cellSize),  // 24
    Offset(7 * cellSize, 0 * cellSize),  // 25
    Offset(8 * cellSize, 0 * cellSize),  // 26
    Offset(8 * cellSize, 1 * cellSize),  // 27 (safe)
    Offset(8 * cellSize, 2 * cellSize),  // 28
    Offset(8 * cellSize, 3 * cellSize),  // 29
    Offset(8 * cellSize, 4 * cellSize),  // 30
    Offset(8 * cellSize, 5 * cellSize),  // 31
    Offset(9 * cellSize, 6 * cellSize),  // 32
    Offset(10 * cellSize, 6 * cellSize), // 33
    Offset(11 * cellSize, 6 * cellSize), // 34
    Offset(12 * cellSize, 6 * cellSize), // 35 (safe)
    Offset(13 * cellSize, 6 * cellSize), // 36
    Offset(14 * cellSize, 6 * cellSize), // 37
    Offset(14 * cellSize, 7 * cellSize), // 38
    Offset(14 * cellSize, 8 * cellSize), // 39
    Offset(13 * cellSize, 9 * cellSize), // 40 (safe)
    Offset(12 * cellSize, 9 * cellSize), // 41
    Offset(11 * cellSize, 9 * cellSize), // 42
    Offset(10 * cellSize, 9 * cellSize), // 43
    Offset(9 * cellSize, 9 * cellSize),  // 44
    Offset(8 * cellSize, 10 * cellSize), // 45
    Offset(8 * cellSize, 11 * cellSize), // 46
    Offset(8 * cellSize, 12 * cellSize), // 47
    Offset(8 * cellSize, 13 * cellSize), // 48 (safe)
    Offset(8 * cellSize, 14 * cellSize), // 49
    Offset(7 * cellSize, 14 * cellSize), // 50
    Offset(7 * cellSize, 13 * cellSize), // 51
    Offset(7 * cellSize, 12 * cellSize), // 52
  ];

  // Home stretch positions for each color
  static const Map<String, List<Offset>> homeStretchPositions = {
    'red': [
      Offset(7 * cellSize, 11 * cellSize),
      Offset(7 * cellSize, 10 * cellSize),
      Offset(7 * cellSize, 9 * cellSize),
      Offset(7 * cellSize, 8 * cellSize),
      Offset(7 * cellSize, 7 * cellSize), // Home center
    ],
    'blue': [
      Offset(9 * cellSize, 7 * cellSize),
      Offset(10 * cellSize, 7 * cellSize),
      Offset(11 * cellSize, 7 * cellSize),
      Offset(12 * cellSize, 7 * cellSize),
      Offset(7 * cellSize, 7 * cellSize), // Home center
    ],
    'yellow': [
      Offset(7 * cellSize, 9 * cellSize),
      Offset(7 * cellSize, 10 * cellSize),
      Offset(7 * cellSize, 11 * cellSize),
      Offset(7 * cellSize, 12 * cellSize),
      Offset(7 * cellSize, 7 * cellSize), // Home center
    ],
    'green': [
      Offset(5 * cellSize, 7 * cellSize),
      Offset(4 * cellSize, 7 * cellSize),
      Offset(3 * cellSize, 7 * cellSize),
      Offset(2 * cellSize, 7 * cellSize),
      Offset(7 * cellSize, 7 * cellSize), // Home center
    ],
  };

  static int getColorIndex(String color) {
    switch (color) {
      case 'red': return 0;
      case 'blue': return 1;
      case 'yellow': return 2;
      case 'green': return 3;
      default: return 0;
    }
  }

  static String getColorByIndex(int index) {
    switch (index) {
      case 0: return 'red';
      case 1: return 'blue';
      case 2: return 'yellow';
      case 3: return 'green';
      default: return 'red';
    }
  }
}
