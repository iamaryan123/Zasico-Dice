import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pawn.dart';
import '../../models/room.dart';
import '../../providers/game_provider.dart';
import '../../services/socket_service.dart';
import '../../services/widgets/Game_board.dart';
import '../../utils/game_constant.dart';
import 'dart:async';

// --- NEW DICE WIDGET ---
class CornerDiceWidget extends StatelessWidget {
  final int? diceNumber;
  final bool isMyTurn;
  final VoidCallback onPressed;
  final String playerColor;
  final int remainingTime;

  const CornerDiceWidget({
    super.key,
    required this.diceNumber,
    required this.isMyTurn,
    required this.onPressed,
    required this.playerColor,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    final diceImg = diceNumber != null
        ? GameConstants.getDiceImage(diceNumber!)
        : GameConstants.diceImages[6];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isMyTurn ? onPressed : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: GameConstants.getPlayerColor(playerColor).withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                diceImg,
                width: 36,
                height: 36,
              ),
            ),
          ),
        ),
        if (isMyTurn)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${remainingTime}s',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

// --- PLAYER SECTION WIDGET ---
class PlayerCornerSection extends StatelessWidget {
  final String corner; // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'
  final Room room;
  final String? currentTurnPlayer;
  final String? myPlayerColor;

  const PlayerCornerSection({
    super.key,
    required this.corner,
    required this.room,
    required this.currentTurnPlayer,
    required this.myPlayerColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorMap = {
      'topLeft': 'red',
      'topRight': 'yellow',
      'bottomLeft': 'blue',
      'bottomRight': 'green',
    };
    final colorName = colorMap[corner]!;

    final player = room.players.where((p) => p.color == colorName).toList();
    if (player.isEmpty) return SizedBox.shrink(); // No player for this color

    final p = player.first;
    final isCurrent = p.color == currentTurnPlayer;
    final isMe = p.color == myPlayerColor;
    final playerColor = GameConstants.getPlayerColor(p.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: playerColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: playerColor.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            isMe ? 'YOU' : p.name,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: playerColor, width: 2),
          ),
          child: Center(
            child: Text(
              p.color[0].toUpperCase(),
              style: GoogleFonts.orbitron(
                color: playerColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- MAIN GAME SCREEN ---
class GameApp extends StatefulWidget {
  final SocketService socketService;

  const GameApp({
    super.key,
    required this.socketService,
  });

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> with TickerProviderStateMixin {
  late AnimationController _pawnMoveController;
  List<Pawn> pawns = [];
  int? currentDiceNumber;
  String? currentTurnPlayer;
  String? myPlayerColor;
  Room? room;
  int _remainingTime = 30;
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    _pawnMoveController = AnimationController(
      duration: GameConstants.pawnMoveDuration,
      vsync: this,
    );
    widget.socketService.setGameStateHandler((Room r) {
      setState(() {
        room = r;
        pawns = r.pawns;
        _updateTurnInfo(r);
      });
      _startTurnTimer();
    });
    widget.socketService.setDiceRolledHandler((int diceNumber) {
      setState(() {
        currentDiceNumber = diceNumber;
      });
    });
    widget.socketService.setTurnChangedHandler((String currentPlayer) {
      setState(() {
        currentTurnPlayer = currentPlayer;
        currentDiceNumber = null;
      });
      _startTurnTimer();
    });
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    room = gameProvider.currentRoom;
    final currentPlayer = gameProvider.currentPlayer;
    if (room != null) {
      pawns = room!.pawns;
      _updateTurnInfo(room!);
    }
    if (currentPlayer != null) {
      myPlayerColor = currentPlayer.color;
    }
    widget.socketService.requestGameData();
    _startTurnTimer();
  }

  void _updateTurnInfo(Room room) {
    final currentPlayer = room.players.firstWhere(
          (p) => p.nowMoving == true,
      orElse: () => room.players.first,
    );
    currentTurnPlayer = currentPlayer.color;
    currentDiceNumber = room.rolledNumber;
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _remainingTime = 30;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime--;
        });
        if (_remainingTime <= 0) {
          _turnTimer?.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _pawnMoveController.dispose();
    super.dispose();
  }

  void _onDicePressed() {
    if (currentTurnPlayer == myPlayerColor) {
      widget.socketService.rollDice();
    }
  }

  // --- Helper to position widgets at corners ---
  Widget _cornerWidget(Widget child, String corner) {
    switch (corner) {
      case 'topLeft':
        return Positioned(
          left: 0,
          top: 0,
          child: child,
        );
      case 'topRight':
        return Positioned(
          right: 0,
          top: 0,
          child: child,
        );
      case 'bottomLeft':
        return Positioned(
          left: 0,
          bottom: 0,
          child: child,
        );
      case 'bottomRight':
        return Positioned(
          right: 0,
          bottom: 0,
          child: child,
        );
      default:
        return child;
    }
  }

  // --- Helper to position dice near current player ---
  Widget _diceForCurrentPlayer() {
    if (room == null || currentTurnPlayer == null) return SizedBox.shrink();
    // Map color to corner
    final colorCorner = {
      'red': 'topLeft',
      'yellow': 'topRight',
      'blue': 'bottomLeft',
      'green': 'bottomRight',
    };
    final corner = colorCorner[currentTurnPlayer!]!;
    return _cornerWidget(
      CornerDiceWidget(
        diceNumber: currentDiceNumber,
        isMyTurn: currentTurnPlayer == myPlayerColor,
        onPressed: _onDicePressed,
        playerColor: currentTurnPlayer!,
        remainingTime: _remainingTime,
      ),
      corner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = GameConstants.boardSize;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [GameConstants.backgroundColor, GameConstants.cardBackgroundColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                // Game Board
                Positioned.fill(
                  child: GameBoard(
                    pawns: pawns,
                    movablePawns: [], // You can pass movable pawns if needed
                    onPawnPressed: (_) {},
                    pawnMoveAnimation: _pawnMoveController,
                  ),
                ),
                // Player sections at corners
                if (room != null) ...[
                  _cornerWidget(
                    PlayerCornerSection(
                      corner: 'topLeft',
                      room: room!,
                      currentTurnPlayer: currentTurnPlayer,
                      myPlayerColor: myPlayerColor,
                    ),
                    'topLeft',
                  ),
                  _cornerWidget(
                    PlayerCornerSection(
                      corner: 'topRight',
                      room: room!,
                      currentTurnPlayer: currentTurnPlayer,
                      myPlayerColor: myPlayerColor,
                    ),
                    'topRight',
                  ),
                  _cornerWidget(
                    PlayerCornerSection(
                      corner: 'bottomLeft',
                      room: room!,
                      currentTurnPlayer: currentTurnPlayer,
                      myPlayerColor: myPlayerColor,
                    ),
                    'bottomLeft',
                  ),
                  _cornerWidget(
                    PlayerCornerSection(
                      corner: 'bottomRight',
                      room: room!,
                      currentTurnPlayer: currentTurnPlayer,
                      myPlayerColor: myPlayerColor,
                    ),
                    'bottomRight',
                  ),
                  // Dice widget for current player
                  _diceForCurrentPlayer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}