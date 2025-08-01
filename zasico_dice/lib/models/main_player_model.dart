// import 'dart:ui';
// import 'package:flame/components.dart';
//
// import '../screens/component/ui_components/token.dart';
//
// class Player {
//   // Core identifiers
//   String playerId;
//   String? userId;
//   String name;
//   String? sessionId;
//
//   // Game state
//   List<Token> tokens;
//   bool isCurrentTurn;
//   int rank;
//   int totalTokensInHome;
//   bool hasWon;
//   int extraTurns;
//   bool enableDice;
//
//   // Online-specific properties
//   bool ready;
//   String color; // Now stores color hex string
//   String colorName;
//   bool isOnline;
//   bool paidEntry;
//
//   Player({
//     required this.playerId,
//     required this.tokens,
//     this.userId,
//     this.name = '',
//     this.sessionId,
//     this.isCurrentTurn = false,
//     this.rank = 0,
//     this.totalTokensInHome = 0,
//     this.hasWon = false,
//     this.extraTurns = 0,
//     this.enableDice = false,
//     this.ready = false,
//     this.color = '#FF5B5B', // default red
//     this.colorName = 'red',
//     this.isOnline = false,
//     this.paidEntry = false,
//   }) {
//     // 🔥 FIX: Ensure color is always a valid hex string
//     color = _normalizeColor(color);
//
//     if (tokens.isEmpty) {
//       initializeTokens();
//     }
//
//     if (!isOnline) {
//       _setColorFromPlayerId(); // For offline only
//     }
//   }
//
//   // 🔥 ADD THIS GETTER TO FIX THE ERROR
//   String get id => playerId;
//
//   // 🔥 NEW METHOD: Normalize color input to ensure it's always a valid hex
//   String _normalizeColor(String inputColor) {
//     // If it's already a valid hex color, return it
//     if (inputColor.startsWith('#') && inputColor.length == 7) {
//       return inputColor;
//     }
//
//     // If it's a color name, convert to hex
//     return _getColorHexFromName(inputColor);
//   }
//
//   // 🟢 For offline game
//   factory Player.offline({
//     required String playerId,
//     List<Token>? tokens,
//     bool isCurrentTurn = false,
//   }) {
//     return Player(
//       playerId: playerId,
//       tokens: tokens ?? [],
//       isCurrentTurn: isCurrentTurn,
//       isOnline: false,
//       name: _getDefaultNameFromPlayerId(playerId),
//     );
//   }
//
//   factory Player.fromBackend({
//     required Map<String, dynamic> data,
//     List<Token>? tokens,
//   }) {
//     final colorName = data['color'] ?? 'red';
//     final playerId = _getPlayerIdFromColor(colorName);
//     final hexColor = _getColorHexFromName(colorName);
//
//     return Player(
//       playerId: playerId,
//       userId: data['_id'] ?? data['userId'], // Handle both _id and userId
//       name: data['name'] ?? 'Player',
//       sessionId: data['sessionID'],
//       tokens: tokens ?? [],
//       isCurrentTurn: data['nowMoving'] ?? false,
//       ready: data['ready'] ?? false,
//       colorName: colorName,
//       color: hexColor, // This will always be a valid hex now
//       isOnline: true,
//       paidEntry: data['paidEntry'] ?? false,
//     );
//   }
//
//   Map<String, dynamic> toBackend() {
//     return {
//       'userId': userId,
//       'sessionID': sessionId,
//       'name': name,
//       'color': colorName, // Send color name to backend, not hex
//       'ready': ready,
//       'nowMoving': isCurrentTurn,
//       'paidEntry': paidEntry,
//     };
//   }
//
//   void initializeTokens() {
//     tokens.clear();
//     for (int i = 0; i < 4; i++) {
//       final token = Token(
//         tokenId: '${playerId}_$i',
//         playerId: playerId,
//         topColor: _colorFromHex(color),
//         sideColor: _colorFromHex(color),
//         position: Vector2(0, 0),
//         size: Vector2(0, 0),
//         tokenIndex: i,
//         currentPosition: '',
//       );
//
//       token.currentPosition = _getBasePosition(i);
//       token.tokenState = TokenState.atBase;
//       tokens.add(token);
//     }
//   }
//
//   void _setColorFromPlayerId() {
//     switch (playerId) {
//       case 'RP':
//         color = '#FF5B5B';
//         colorName = 'red';
//         break;
//       case 'BP':
//         color = '#0D92F4';
//         colorName = 'blue';
//         break;
//       case 'GP':
//         color = '#41B06E';
//         colorName = 'green';
//         break;
//       case 'YP':
//         color = '#FFD966';
//         colorName = 'yellow';
//         break;
//       default:
//         color = '#FF5B5B';
//         colorName = 'red';
//     }
//   }
//
//   String _getBasePosition(int tokenIndex) {
//     switch (playerId) {
//       case 'RP': return 'RB$tokenIndex';
//       case 'BP': return 'BB$tokenIndex';
//       case 'GP': return 'GB$tokenIndex';
//       case 'YP': return 'YB$tokenIndex';
//       default: return 'RB$tokenIndex';
//     }
//   }
//
//   bool allTokensInBase() {
//     return tokens.every((token) => token.isInBase());
//   }
//
//   List<Token> getTokensOnBoard() {
//     _cachedTokensOnBoard ??= tokens.where((token) => token.isOnBoard()).toList();
//     return _cachedTokensOnBoard!;
//   }
//
//   bool hasOneTokenOnBoard() => getTokensOnBoard().length == 1;
//   bool hasMultipleTokensOnBoard() => getTokensOnBoard().length > 1;
//
//   Future<void> resetExtraTurns() async {
//     extraTurns = 0;
//     _cachedTokensOnBoard = null;
//     return Future.value();
//   }
//
//   void grantAnotherTurn() {
//     extraTurns++;
//     enableDice = true;
//   }
//
//   bool hasRolledThreeConsecutiveSixes() => extraTurns == 3;
//
//   void toggleReady() => ready = !ready;
//   void setReady(bool isReady) => ready = isReady;
//
//   void setCurrentTurn(bool isTurn) {
//     isCurrentTurn = isTurn;
//     enableDice = isTurn;
//   }
//
//   void updateFromBackend(Map<String, dynamic> data) {
//     name = data['name'] ?? name;
//     isCurrentTurn = data['nowMoving'] ?? isCurrentTurn;
//     ready = data['ready'] ?? ready;
//     paidEntry = data['paidEntry'] ?? paidEntry;
//
//     // 🔥 FIX: Handle color updates properly
//     if (data.containsKey('color')) {
//       final newColorName = data['color'];
//       if (newColorName != colorName) {
//         colorName = newColorName;
//         color = _getColorHexFromName(newColorName);
//       }
//     }
//
//     enableDice = isCurrentTurn;
//   }
//
//   void syncTokensWithBackend(List<dynamic> backendPawns) {
//     // Reset token count
//     totalTokensInHome = 0;
//
//     for (var pawnData in backendPawns) {
//       if (pawnData['color'] == colorName) {
//         final tokenIndex = pawnData['basePos'] % 4;
//         if (tokenIndex < tokens.length) {
//           final token = tokens[tokenIndex];
//           final serverPosition = pawnData['position'];
//           final basePos = pawnData['basePos'];
//
//           if (serverPosition == basePos) {
//             token.currentPosition = _getBasePosition(tokenIndex);
//             token.tokenState = TokenState.atBase;
//           } else {
//             token.currentPosition = _convertServerPositionToLocal(serverPosition);
//             if (_isInFinishArea(serverPosition)) {
//               token.tokenState = TokenState.atFinish;
//               totalTokensInHome++;
//             } else {
//               token.tokenState = TokenState.onBoard;
//             }
//           }
//         }
//       }
//     }
//
//     hasWon = totalTokensInHome >= 4;
//   }
//
//   String _convertServerPositionToLocal(int serverPosition) {
//     final paths = {
//       'RP': ['R10', 'R20', 'R30'],
//       'BP': ['B04', 'B03', 'B02'],
//       'GP': ['G21', 'G22', 'G23'],
//       'YP': ['Y42', 'Y32', 'Y22'],
//     };
//
//     final path = paths[playerId] ?? paths['RP']!;
//     if (serverPosition < path.length) {
//       return path[serverPosition];
//     }
//
//     return path.first;
//   }
//
//   bool _isInFinishArea(int serverPosition) {
//     const finishPositions = {
//       'red': [69, 70, 71, 72, 73],
//       'blue': [75, 76, 77, 78, 79],
//       'green': [81, 82, 83, 84, 85],
//       'yellow': [87, 88, 89, 90, 91],
//     };
//
//     return finishPositions[colorName]?.contains(serverPosition) ?? false;
//   }
//
//   static String _getDefaultNameFromPlayerId(String playerId) {
//     switch (playerId) {
//       case 'RP': return 'Red Player';
//       case 'BP': return 'Blue Player';
//       case 'GP': return 'Green Player';
//       case 'YP': return 'Yellow Player';
//       default: return 'Player';
//     }
//   }
//
//   static String _getPlayerIdFromColor(String colorName) {
//     switch (colorName.toLowerCase()) {
//       case 'red': return 'RP';
//       case 'blue': return 'BP';
//       case 'green': return 'GP';
//       case 'yellow': return 'YP';
//       default: return 'RP';
//     }
//   }
//
//   static String _getColorHexFromName(String colorName) {
//     switch (colorName.toLowerCase()) {
//       case 'red': return '#FF5B5B';
//       case 'blue': return '#0D92F4';
//       case 'green': return '#41B06E';
//       case 'yellow': return '#FFD966';
//       default: return '#FF5B5B';
//     }
//   }
//
//   // 🔥 IMPROVED: Better error handling for hex color parsing
//   static Color _colorFromHex(String hex) {
//     try {
//       // Remove # if present
//       String hexCode = hex.replaceAll('#', '');
//
//       // Validate hex string
//       if (hexCode.length != 6) {
//         print('⚠️ Invalid hex color length: $hex, using default red');
//         hexCode = 'FF5B5B'; // Default red
//       }
//
//       // Validate hex characters
//       if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(hexCode)) {
//         print('⚠️ Invalid hex color format: $hex, using default red');
//         hexCode = 'FF5B5B'; // Default red
//       }
//
//       return Color(int.parse('FF$hexCode', radix: 16));
//     } catch (e) {
//       print('❌ Error parsing hex color "$hex": $e');
//       print('🔧 Using default red color instead');
//       return Color(int.parse('FFFF5B5B', radix: 16)); // Default red
//     }
//   }
//
//   @override
//   String toString() {
//     return 'Player(id: $playerId, name: $name, color: $colorName, '
//         'turn: $isCurrentTurn, ready: $ready, online: $isOnline)';
//   }
//
//   List<Token>? _cachedTokensOnBoard;
// }