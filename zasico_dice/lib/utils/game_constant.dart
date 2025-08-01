import 'package:flutter/material.dart';

class GameConstants {
  // Player Colors - Updated to match your theme
  static const Color redColor = Color(0xFFE53E3E);
  static const Color blueColor = Color(0xFF3182CE);
  static const Color greenColor = Color(0xFF48BB78);
  static const Color yellowColor = Color(0xFFECC94B);
  static const Color greyColor = Color(0xFF9CA3AF);

  // Player color mapping
  static const Map<String, Color> playerColors = {
    'red': redColor,
    'blue': blueColor,
    'green': greenColor,
    'yellow': yellowColor,
    'grey': greyColor,
  };

  // Board dimensions - Increased for better visibility
  static const double boardSize = 360.0; // Increased from 460
  static const double pawnSize = 28.0; // Slightly smaller for better fit
  static const double pawnRadius = 14.0;
  static const double touchRadius = 35.0; // Increased touch area

  // Animation durations
  static const Duration pawnMoveDuration = Duration(milliseconds: 800);
  static const Duration diceRollDuration = Duration(milliseconds: 600);
  static const Duration turnTransitionDuration = Duration(milliseconds: 300);
  static const Duration waitingDuration = Duration(seconds: 30); // Turn timer

  // Board positions - Adjusted for new board size (scaled down from 460 to 360)
  static const List<Offset> boardPositions = [
    // Red base (0-3) - Top Left
    Offset(52, 52), Offset(52, 91), Offset(91, 52), Offset(91, 91),

    // Blue base (4-7) - Bottom Left
    Offset(52, 268), Offset(52, 307), Offset(91, 268), Offset(91, 307),

    // Green base (8-11) - Bottom Right
    Offset(268, 268), Offset(307, 307), Offset(307, 268), Offset(268, 307),

    // Yellow base (12-15) - Top Right
    Offset(268, 52), Offset(307, 91), Offset(307, 52), Offset(268, 91),

    // Main board path (16-67) - Adjusted coordinates
    Offset(35, 156), Offset(59, 156), Offset(84, 156), Offset(108, 156), Offset(132, 156), // 16-20
    Offset(156, 132), Offset(156, 108), Offset(156, 84), Offset(156, 59), Offset(156, 35), Offset(156, 11), // 21-26
    Offset(180, 11), Offset(204, 11), Offset(204, 35), Offset(204, 59), // 27-30
    Offset(204, 84), Offset(204, 108), Offset(204, 132), // 31-33
    Offset(228, 156), Offset(251, 156), Offset(275, 156), Offset(299, 156), Offset(324, 156), Offset(348, 156), // 34-39
    Offset(348, 180), // 40
    Offset(348, 204), Offset(324, 204), Offset(299, 204), Offset(275, 204), Offset(251, 204), Offset(228, 204), // 41-46
    Offset(204, 228), Offset(204, 252), Offset(204, 276), Offset(204, 300), // 47-50
    Offset(204, 324), Offset(204, 348), // 51-52
    Offset(180, 348), // 53
    Offset(156, 348), Offset(156, 324), Offset(156, 300), Offset(156, 276), Offset(156, 252), Offset(156, 228), // 54-59
    Offset(132, 204), Offset(108, 204), Offset(84, 204), Offset(59, 204), Offset(35, 204), // 60-64
    Offset(12, 204), // 65
    Offset(12, 180), // 66
    Offset(12, 156), // 67

    // Red finish path (68-73)
    Offset(35, 180), Offset(59, 180), Offset(84, 180), Offset(108, 180), Offset(132, 180), Offset(156, 180),

    // Blue finish path (74-79)
    Offset(180, 324), Offset(180, 300), Offset(180, 276), Offset(180, 252), Offset(180, 228), Offset(180, 204),

    // Green finish path (80-85)
    Offset(324, 180), Offset(299, 180), Offset(275, 180), Offset(251, 180), Offset(227, 180), Offset(203, 180),

    // Yellow finish path (86-91)
    Offset(180, 35), Offset(180, 59), Offset(180, 84), Offset(180, 108), Offset(180, 132), Offset(180, 156),
  ];

  // Dice images paths
  static const List<String> diceImages = [
    'assets/images/dice/1.png',
    'assets/images/dice/2.png',
    'assets/images/dice/3.png',
    'assets/images/dice/4.png',
    'assets/images/dice/5.png',
    'assets/images/dice/6.png',
    'assets/images/dice/roll.png', // Rolling animation
  ];

  // Pawn images paths
  static const Map<String, String> pawnImages = {
    'red': 'assets/images/pawns/red_pawn.png',
    'blue': 'assets/images/pawns/blue_pawn.png',
    'green': 'assets/images/pawns/green_pawn.png',
    'yellow': 'assets/images/pawns/yellow_pawn.png',
    'grey': 'assets/images/pawns/grey_pawn.png',
  };

  // Board image
  static const String boardImage = 'assets/images/ludo_board.jpg';

  // Game rules
  static const int maxPlayersPerRoom = 4;
  static const int pawnsPerPlayer = 4;
  static const int diceToMoveFromBase = 6; // or 1
  static const int positionsToWin = 4; // All pawns must reach finish
  static const int turnTimeLimit = 30; // seconds

  // Base positions for each color
  static const Map<String, List<int>> basePositions = {
    'red': [0, 1, 2, 3],
    'blue': [4, 5, 6, 7],
    'green': [8, 9, 10, 11],
    'yellow': [12, 13, 14, 15],
  };

  // Starting positions when leaving base
  static const Map<String, int> startingPositions = {
    'red': 16,
    'blue': 55,
    'green': 42,
    'yellow': 29,
  };

  // Finish line positions (last position before home)
  static const Map<String, int> finishLinePositions = {
    'red': 73,
    'blue': 79,
    'green': 85,
    'yellow': 91,
  };

  // Safe positions (where pawns cannot be captured)
  static const List<int> safePositions = [
    16, 29, 42, 55, // Starting positions
    21, 34, 47, 60, // Middle safe spots
  ];

  // UI Constants - Enhanced
  static const double headerHeight = 80.0;
  static const double diceContainerSize = 90.0;
  static const double playerInfoHeight = 70.0;
  static const double bottomPadding = 16.0;
  static const double timerBarHeight = 6.0;

  // Colors for UI - Professional dark theme
  static const Color backgroundColor = Color(0xFF0F1419);
  static const Color cardBackgroundColor = Color(0xFF1E2328);
  static const Color surfaceColor = Color(0xFF252A31);
  static const Color primaryTextColor = Color(0xFFE6E8EA);
  static const Color secondaryTextColor = Color(0xFF9DA3AE);
  static const Color accentColor = Color(0xFF00D9FF);
  static const Color successColor = Color(0xFF00C851);
  static const Color warningColor = Color(0xFFFF8800);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color dividerColor = Color(0xFF3C4043);

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF1E2328),
    Color(0xFF252A31),
  ];

  // Helper methods
  static Color getPlayerColor(String colorName) {
    return playerColors[colorName.toLowerCase()] ?? greyColor;
  }

  static String getDiceImage(int diceNumber) {
    if (diceNumber >= 1 && diceNumber <= 6) {
      return diceImages[diceNumber - 1];
    }
    return diceImages[6]; // Rolling image
  }

  static String getPawnImage(String colorName) {
    return pawnImages[colorName.toLowerCase()] ?? pawnImages['grey']!;
  }

  static List<int> getBasePositionsForColor(String colorName) {
    return basePositions[colorName.toLowerCase()] ?? basePositions['red']!;
  }

  static int getStartingPositionForColor(String colorName) {
    return startingPositions[colorName.toLowerCase()] ?? startingPositions['red']!;
  }

  static int getFinishLinePositionForColor(String colorName) {
    return finishLinePositions[colorName.toLowerCase()] ?? finishLinePositions['red']!;
  }

  static bool isSafePosition(int position) {
    return safePositions.contains(position);
  }

  static Offset getPositionCoordinates(int position) {
    if (position >= 0 && position < boardPositions.length) {
      return boardPositions[position];
    }
    return const Offset(0, 0);
  }

  // Game state helpers
  static bool canPawnMoveFromBase(int diceNumber) {
    return diceNumber == 1 || diceNumber == 6;
  }

  // Add this helper method to GameConstants class
  static List<String> getPlayerColorsInOrder(String myColor) {
    const allColors = ['red', 'yellow', 'blue', 'green'];
    if (!allColors.contains(myColor)) return allColors;

    final myIndex = allColors.indexOf(myColor);
    return [
      ...allColors.sublist(myIndex + 1),
      ...allColors.sublist(0, myIndex),
      myColor,
    ];
  }

  static bool doesPlayerGetAnotherTurn(int diceNumber) {
    return diceNumber == 6;
  }

  // Animation curves
  static const Curve pawnMoveAnimationCurve = Curves.easeInOutCubic;
  static const Curve diceRollAnimationCurve = Curves.elasticOut;
  static const Curve scaleAnimationCurve = Curves.bounceOut;
  static const Curve slideAnimationCurve = Curves.easeOutQuart;

  // Professional styling
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: surfaceGradient,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: dividerColor,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get glowDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: accentColor.withOpacity(0.3),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );
}