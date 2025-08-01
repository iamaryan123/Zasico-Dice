// // screens/game_screen.dart (Enhanced version)
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../models/ludo_board_data.dart';
// import '../../models/pawn.dart';
// import '../../models/player.dart';
// import '../../models/room.dart';
// import '../../providers/game_provider.dart';
// import '../../services/socket_service.dart';
// import '../../utils/colors.dart';
// import '../components/dice.dart';
// import '../components/ludo_board_widget.dart';
// import '../components/player_panel.dart';
//
// class Game extends StatefulWidget {
//   final SocketService socketService;
//
//   const Game({super.key, required this.socketService});
//
//   @override
//   State<Game> createState() => _GameState();
// }
//
// class _GameState extends State<Game>
//     with TickerProviderStateMixin {
//   late AnimationController _diceController;
//   late AnimationController _turnHighlightController;
//
//   int? _rolledNumber;
//   bool _isRolling = false;
//   String? _highlightedPawnId;
//   List<String> _movablePawns = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _setupSocketListeners();
//     _requestGameData();
//   }
//
//   void _setupAnimations() {
//     _diceController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _turnHighlightController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     )..repeat(reverse: true);
//   }
//
//   void _setupSocketListeners() {
//     // Dice roll result
//     widget.socketService.socket.on('game:roll_result', (data) {
//       if (mounted) {
//         setState(() {
//           _rolledNumber = data['diceNumber'];
//           _isRolling = false;
//           _movablePawns = List<String>.from(data['movablePawns'] ?? []);
//         });
//         _diceController.stop();
//       }
//     });
//
//     // Pawn movement
//     widget.socketService.socket.on('game:pawn_moved', (data) {
//       if (mounted) {
//         final gameProvider = Provider.of<GameProvider>(context, listen: false);
//         gameProvider.updatePawnPosition(data['pawnId'], data['newPosition']);
//
//         setState(() {
//           _highlightedPawnId = null;
//           _movablePawns = [];
//         });
//       }
//     });
//
//     // Turn change
//     widget.socketService.socket.on('game:turn_changed', (data) {
//       if (mounted) {
//         setState(() {
//           _rolledNumber = null;
//           _movablePawns = [];
//           _highlightedPawnId = null;
//         });
//
//         final gameProvider = Provider.of<GameProvider>(context, listen: false);
//         gameProvider.setCurrentTurn(data['currentPlayer']);
//       }
//     });
//
//     // Game state update
//     widget.socketService.socket.on('game:state_update', (data) {
//       if (mounted) {
//         final gameProvider = Provider.of<GameProvider>(context, listen: false);
//         gameProvider.updateGameState(data);
//       }
//     });
//
//     // Game winner
//     widget.socketService.socket.on('game:winner', (data) {
//       if (mounted) {
//         _showWinnerDialog(data['winner']);
//       }
//     });
//
//     // Invalid move
//     widget.socketService.socket.on('game:invalid_move', (data) {
//       if (mounted) {
//         _showError(data['message'] ?? 'Invalid move');
//         setState(() {
//           _movablePawns = [];
//           _highlightedPawnId = null;
//         });
//       }
//     });
//
//     // Room data updates
//     widget.socketService.socket.on('room:data', (data) {
//       if (mounted) {
//         final roomData = data is String ? jsonDecode(data) : data;
//         final gameProvider = Provider.of<GameProvider>(context, listen: false);
//         gameProvider.updateRoom(Room.fromJson(roomData));
//       }
//     });
//   }
//
//   void _requestGameData() {
//     widget.socketService.socket.emit('room:data');
//   }
//
//   void _rollDice() {
//     final gameProvider = Provider.of<GameProvider>(context, listen: false);
//
//     if (_isRolling || !gameProvider.isMyTurn) return;
//
//     setState(() {
//       _isRolling = true;
//       _rolledNumber = null;
//       _movablePawns = [];
//     });
//
//     _diceController.repeat();
//     widget.socketService.rollDiceEnhanced();
//   }
//
//   void _movePawn(String pawnId) {
//     if (!_movablePawns.contains(pawnId)) return;
//
//     setState(() {
//       _highlightedPawnId = pawnId;
//     });
//
//     final gameProvider = Provider.of<GameProvider>(context, listen: false);
//     final pawn = gameProvider.currentRoom?.pawns.firstWhere((p) => p.id == pawnId);
//
//     if (pawn != null) {
//       final fromPosition = pawn.position.toString();
//       final toPosition = _calculateNewPosition(pawn, _rolledNumber ?? 0).toString();
//
//       widget.socketService.movePawnEnhanced(pawnId, fromPosition, toPosition);
//     }
//   }
//
//   int _calculateNewPosition(Pawn pawn, int diceRoll) {
//     if (pawn.isAtHome && diceRoll == 6) {
//       return 1; // Move to starting position
//     }
//
//     if (pawn.isAtHome) {
//       return pawn.position; // Can't move
//     }
//
//     int newPosition = pawn.position + diceRoll;
//
//     // Check if pawn reaches home
//     if (newPosition > 56) {
//       return pawn.position; // Can't move past home
//     }
//
//     return newPosition;
//   }
//
//   void _showWinnerDialog(String winnerColor) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => WinnerDialog(winnerColor: winnerColor),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: GoogleFonts.orbitron()),
//         backgroundColor: Colors.red[800],
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _diceController.dispose();
//     _turnHighlightController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: ZasicoColors.primaryBackground,
//       body: SafeArea(
//         child: Consumer<GameProvider>(
//           builder: (context, gameProvider, _) {
//             if (gameProvider.isLoading) {
//               return _buildLoadingScreen();
//             }
//
//             return Column(
//               children: [
//                 _buildGameHeader(gameProvider),
//                 Expanded(child: _buildGameBody(gameProvider)),
//                 _buildGameControls(gameProvider),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoadingScreen() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(color: ZasicoColors.primaryRed),
//           const SizedBox(height: 20),
//           Text(
//             'Setting up the board...',
//             style: GoogleFonts.orbitron(
//               color: ZasicoColors.primaryText,
//               fontSize: 18,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGameHeader(GameProvider gameProvider) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: ZasicoColors.cardBackground,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             gameProvider.currentRoom?.name ?? 'Ludo Match',
//             style: GoogleFonts.orbitron(
//               color: ZasicoColors.primaryText,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Row(
//             children: [
//               if (_rolledNumber != null) ...[
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: ZasicoColors.primaryRed,
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(
//                     'Rolled: $_rolledNumber',
//                     style: GoogleFonts.orbitron(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//               ],
//               AnimatedBuilder(
//                 animation: _turnHighlightController,
//                 builder: (context, child) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: gameProvider.isMyTurn
//                           ? Colors.green.withOpacity(_turnHighlightController.value * 0.5 + 0.5)
//                           : Colors.grey[700],
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       gameProvider.isMyTurn ? 'YOUR TURN' : 'WAITING',
//                       style: GoogleFonts.orbitron(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGameBody(GameProvider gameProvider) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           // Top players (red and blue)
//           Row(
//             children: [
//               PlayerPanel(
//                 player: gameProvider.getPlayerByColor('red'),
//                 position: PlayerPosition.top,
//                 isActive: gameProvider.currentTurnColor == 'red',
//                 pawnsAtHome: gameProvider.getPawnsAtHome('red'),
//               ),
//               const SizedBox(width: 8),
//               PlayerPanel(
//                 player: gameProvider.getPlayerByColor('blue'),
//                 position: PlayerPosition.top,
//                 isActive: gameProvider.currentTurnColor == 'blue',
//                 pawnsAtHome: gameProvider.getPawnsAtHome('blue'),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 16),
//
//           // Game board
//           Expanded(
//             child: Center(
//               child: LudoBoardWidget(
//                 pawns: gameProvider.currentRoom?.pawns ?? [],
//                 onPawnTap: _movePawn,
//                 highlightedPawnId: _highlightedPawnId,
//                 movablePawns: _movablePawns,
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // Bottom players (green and yellow)
//           Row(
//             children: [
//               PlayerPanel(
//                 player: gameProvider.getPlayerByColor('green'),
//                 position: PlayerPosition.bottom,
//                 isActive: gameProvider.currentTurnColor == 'green',
//                 pawnsAtHome: gameProvider.getPawnsAtHome('green'),
//               ),
//               const SizedBox(width: 8),
//               PlayerPanel(
//                 player: gameProvider.getPlayerByColor('yellow'),
//                 position: PlayerPosition.bottom,
//                 isActive: gameProvider.currentTurnColor == 'yellow',
//                 pawnsAtHome: gameProvider.getPawnsAtHome('yellow'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGameControls(GameProvider gameProvider) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: ZasicoColors.cardBackground,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Prize pool
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'PRIZE POOL',
//                 style: GoogleFonts.orbitron(
//                   color: ZasicoColors.secondaryText,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 '\${gameProvider.currentRoom?.prizePool.toStringAsFixed(0) ?? 0}',
//                 style: GoogleFonts.orbitron(
//                   color: ZasicoColors.primaryRed,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//
//           const Spacer(),
//
//           // Game status
//           if (_movablePawns.isNotEmpty) ...[
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.orange,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Text(
//                 'Select Pawn to Move',
//                 style: GoogleFonts.orbitron(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//           ],
//
//           // Dice
//           Dice3D(
//             number: _rolledNumber,
//             isRolling: _isRolling,
//             onRoll: _rollDice,
//             enabled: gameProvider.isMyTurn && !_isRolling && _movablePawns.isEmpty,
//           ),
//
//           const Spacer(),
//
//           // Game menu
//           IconButton(
//             icon: const Icon(Icons.menu, color: Colors.white, size: 30),
//             onPressed: () => _showGameMenu(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showGameMenu() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: ZasicoColors.cardBackground,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 50,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[600],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: const Icon(Icons.sync, color: Colors.blue),
//               title: Text('Sync Game', style: GoogleFonts.orbitron()),
//               subtitle: Text('Refresh game state', style: GoogleFonts.roboto()),
//               onTap: () {
//                 Navigator.pop(context);
//                 widget.socketService.requestGameState();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.help, color: Colors.green),
//               title: Text('Game Rules', style: GoogleFonts.orbitron()),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showGameRules();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.pause, color: Colors.orange),
//               title: Text('Pause Game', style: GoogleFonts.orbitron()),
//               onTap: () {
//                 Navigator.pop(context);
//                 widget.socketService.pauseGame();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.exit_to_app, color: Colors.red),
//               title: Text('Leave Game', style: GoogleFonts.orbitron()),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showLeaveConfirmation();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showLeaveConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: ZasicoColors.cardBackground,
//         title: Text('Leave Game?', style: GoogleFonts.orbitron(color: Colors.white)),
//         content: Text(
//           'Are you sure you want to leave the game? You will lose your progress.',
//           style: GoogleFonts.roboto(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel', style: GoogleFonts.orbitron(color: Colors.grey)),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               widget.socketService.leaveRoom();
//               Navigator.popUntil(context, (route) => route.isFirst);
//             },
//             child: Text('Leave', style: GoogleFonts.orbitron(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showGameRules() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: ZasicoColors.cardBackground,
//         title: Text('Ludo Rules', style: GoogleFonts.orbitron(color: Colors.white)),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildRuleItem('🎲', 'Roll a 6 to move a pawn out of base'),
//               _buildRuleItem('⚔️', 'Capture opponents by landing on their pawn'),
//               _buildRuleItem('🛡️', 'Safe spots (marked with stars) protect your pawns'),
//               _buildRuleItem('🏠', 'Move all pawns to the center triangle to win'),
//               _buildRuleItem('🔄', 'Roll again if you get a 6 or capture a pawn'),
//               _buildRuleItem('📍', 'Pawns in home stretch are safe from capture'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Got it!', style: GoogleFonts.orbitron(color: ZasicoColors.primaryRed)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRuleItem(String emoji, String rule) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 16)),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               rule,
//               style: GoogleFonts.roboto(fontSize: 14, color: Colors.white70),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Winner Dialog (Enhanced)
// class WinnerDialog extends StatefulWidget {
//   final String winnerColor;
//
//   const WinnerDialog({super.key, required this.winnerColor});
//
//   @override
//   State<WinnerDialog> createState() => _WinnerDialogState();
// }
//
// class _WinnerDialogState extends State<WinnerDialog>
//     with TickerProviderStateMixin {
//   late AnimationController _confettiController;
//   late AnimationController _scaleController;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _confettiController = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     );
//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _scaleAnimation = CurvedAnimation(
//       parent: _scaleController,
//       curve: Curves.elasticOut,
//     );
//
//     _confettiController.forward();
//     _scaleController.forward();
//   }
//
//   @override
//   void dispose() {
//     _confettiController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: ScaleTransition(
//         scale: _scaleAnimation,
//         child: Container(
//           padding: const EdgeInsets.all(30),
//           decoration: BoxDecoration(
//             color: ZasicoColors.cardBackground,
//             borderRadius: BorderRadius.circular(20),
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 _getPlayerColor(widget.winnerColor).withOpacity(0.3),
//                 ZasicoColors.cardBackground,
//               ],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: _getPlayerColor(widget.winnerColor).withOpacity(0.5),
//                 blurRadius: 20,
//                 spreadRadius: 5,
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedBuilder(
//                 animation: _confettiController,
//                 builder: (context, child) {
//                   return Transform.rotate(
//                     angle: _confettiController.value * 2 * 3.14159,
//                     child: Icon(
//                       Icons.emoji_events,
//                       size: 80,
//                       color: _getPlayerColor(widget.winnerColor),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'VICTORY!',
//                 style: GoogleFonts.orbitron(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                   letterSpacing: 2,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 '${widget.winnerColor.toUpperCase()} PLAYER WINS',
//                 style: GoogleFonts.orbitron(
//                   fontSize: 20,
//                   color: _getPlayerColor(widget.winnerColor),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '🎉 Congratulations! 🎉',
//                       style: GoogleFonts.orbitron(
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Great strategy and excellent moves!',
//                       style: GoogleFonts.roboto(
//                         fontSize: 14,
//                         color: Colors.white70,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.grey[700],
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       icon: const Icon(Icons.replay, color: Colors.white),
//                       label: Text(
//                         'PLAY AGAIN',
//                         style: GoogleFonts.orbitron(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         // Handle play again logic
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ZasicoColors.primaryRed,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       icon: const Icon(Icons.home, color: Colors.white),
//                       label: Text(
//                         'HOME',
//                         style: GoogleFonts.orbitron(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.popUntil(context, (route) => route.isFirst);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getPlayerColor(String color) {
//     switch (color) {
//       case 'red': return ZasicoColors.primaryRed;
//       case 'blue': return Colors.blue;
//       case 'green': return Colors.green;
//       case 'yellow': return Colors.yellow;
//       default: return Colors.white;
//     }
//   }
// }
//
// // Game Logic Helper (utils/game_logic.dart)
// class GameLogic {
//   static List<String> getMovablePawns(
//       List<Pawn> playerPawns,
//       int diceRoll,
//       String playerColor,
//       ) {
//     List<String> movablePawns = [];
//
//     for (final pawn in playerPawns) {
//       if (canMovePawn(pawn, diceRoll)) {
//         movablePawns.add(pawn.id);
//       }
//     }
//
//     return movablePawns;
//   }
//
//   static bool canMovePawn(Pawn pawn, int diceRoll) {
//     // Can only move out of home with a 6
//     if (pawn.isAtHome && diceRoll != 6) {
//       return false;
//     }
//
//     // Can always move out of home with a 6
//     if (pawn.isAtHome && diceRoll == 6) {
//       return true;
//     }
//
//     // Check if pawn would go past the finish line
//     int newPosition = pawn.position + diceRoll;
//     if (newPosition > 56) {
//       return false;
//     }
//
//     return true;
//   }
//
//   static int calculateNewPosition(Pawn pawn, int diceRoll, String playerColor) {
//     if (pawn.isAtHome && diceRoll == 6) {
//       // Move to starting position
//       return getStartingPosition(playerColor);
//     }
//
//     if (pawn.isAtHome) {
//       return pawn.position; // Can't move
//     }
//
//     int newPosition = pawn.position + diceRoll;
//
//     // Check bounds
//     if (newPosition > 56) {
//       return pawn.position; // Can't move past finish
//     }
//
//     return newPosition;
//   }
//
//   static int getStartingPosition(String color) {
//     switch (color) {
//       case 'red': return 1;
//       case 'blue': return 14;
//       case 'yellow': return 27;
//       case 'green': return 40;
//       default: return 1;
//     }
//   }
//
//   static bool isPositionSafe(int position) {
//     return LudoBoardData.safePositions.contains(position);
//   }
//
//   static bool canCapture(Pawn movingPawn, List<Pawn> allPawns, int newPosition) {
//     // Check if there's an opponent pawn at the new position
//     for (final pawn in allPawns) {
//       if (pawn.color != movingPawn.color &&
//           pawn.position == newPosition &&
//           !pawn.isAtHome &&
//           !isPositionSafe(newPosition)) {
//         return true;
//       }
//     }
//     return false;
//   }
//
//   static List<Pawn> getPawnsToCapture(Pawn movingPawn, List<Pawn> allPawns, int newPosition) {
//     List<Pawn> pawnsToCapture = [];
//
//     for (final pawn in allPawns) {
//       if (pawn.color != movingPawn.color &&
//           pawn.position == newPosition &&
//           !pawn.isAtHome &&
//           !isPositionSafe(newPosition)) {
//         pawnsToCapture.add(pawn);
//       }
//     }
//
//     return pawnsToCapture;
//   }
//
//   static bool hasWon(List<Pawn> playerPawns) {
//     return playerPawns.every((pawn) => pawn.isAtEnd);
//   }
//
//   static String getNextPlayer(String currentPlayer, List<String> playerColors) {
//     int currentIndex = playerColors.indexOf(currentPlayer);
//     int nextIndex = (currentIndex + 1) % playerColors.length;
//     return playerColors[nextIndex];
//   }
// }
//
