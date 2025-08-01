// game_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/pawn.dart';
import '../services/socket_service.dart';

class GameController extends ChangeNotifier {
  final SocketService socketService;

  // Game State
  Room? _currentRoom;
  List<Player> _activePlayers = [];
  List<Pawn> _pawns = [];

  // Turn Management
  String? _currentTurnPlayerId;
  String? _myPlayerId;
  int _currentTurnIndex = 0;
  bool _isMyTurn = false;

  // Dice State
  int? _diceNumber;
  bool _diceRolled = false;
  bool _isDiceRolling = false;

  // Timer
  int _remainingTime = 30;
  Timer? _turnTimer;

  // Movement State
  List<Pawn> _movablePawns = [];
  bool _waitingForMove = false;

  GameController(this.socketService) {
    _setupSocketListeners();
  }

  // Getters
  Room? get currentRoom => _currentRoom;
  List<Player> get activePlayers => _activePlayers;
  List<Pawn> get pawns => _pawns;
  String? get currentTurnPlayerId => _currentTurnPlayerId;
  String? get myPlayerId => _myPlayerId;
  bool get isMyTurn => _isMyTurn;
  int? get diceNumber => _diceNumber;
  bool get diceRolled => _diceRolled;
  bool get isDiceRolling => _isDiceRolling;
  int get remainingTime => _remainingTime;
  List<Pawn> get movablePawns => _movablePawns;
  bool get canRollDice => _isMyTurn && !_diceRolled && !_isDiceRolling;
  bool get canMovePawns => _isMyTurn && _diceRolled && _movablePawns.isNotEmpty;

  Player? get currentTurnPlayer {
    if (_currentTurnPlayerId == null) return null;
    try {
      return _activePlayers.firstWhere((p) => p.userId == _currentTurnPlayerId);
    } catch (e) {
      return null;
    }
  }

  Player? get myPlayer {
    if (_myPlayerId == null) return null;
    try {
      return _activePlayers.firstWhere((p) => p.userId == _myPlayerId);
    } catch (e) {
      return null;
    }
  }

  void _setupSocketListeners() {
    // Game state updates
    socketService.setGameStateHandler((Room room) {
      _updateGameState(room);
    });

    // Game started
    socketService.setGameStartedHandler((Room room) {
      _initializeGame(room);
    });

    // Dice rolled
    socketService.setDiceRolledHandler((int diceNumber) {
      _handleDiceRolled(diceNumber);
    });

    // Turn changed
    socketService.setTurnChangedHandler((String playerId) {
      _handleTurnChanged(playerId);
    });

    // Pawn moved
    socketService.setPawnMovedHandler((Pawn pawn, int fromPos, int toPos) {
      _handlePawnMoved(pawn, fromPos, toPos);
    });

    // Game winner
    socketService.setGameWinnerHandler((String winner) {
      _handleGameWinner(winner);
    });
  }

  void _initializeGame(Room room) {
    print('🎮 Initializing game with ${room.players.length} players');

    _currentRoom = room;
    _activePlayers = room.players.where((p) => p.userId.isNotEmpty).toList();
    _pawns = room.pawns;
    _myPlayerId = socketService.currentUserId;

    // Sort players by join order or predefined order
    _activePlayers.sort((a, b) => _getPlayerOrder(a.color).compareTo(_getPlayerOrder(b.color)));

    // Initialize turn system
    _initializeTurnSystem();

    print('✅ Game initialized:');
    print('   Players: ${_activePlayers.map((p) => '${p.name}(${p.color})').join(', ')}');
    print('   My ID: $_myPlayerId');
    print('   Current turn: $_currentTurnPlayerId');

    notifyListeners();
  }

  void _updateGameState(Room room) {
    _currentRoom = room;
    _pawns = room.pawns;

    // Update players list (handle disconnections/reconnections)
    final newActivePlayers = room.players.where((p) => p.userId.isNotEmpty).toList();
    if (newActivePlayers.length != _activePlayers.length) {
      _activePlayers = newActivePlayers;
      _activePlayers.sort((a, b) => _getPlayerOrder(a.color).compareTo(_getPlayerOrder(b.color)));
    }

    // Update turn info from room data
    final currentPlayer = room.players.firstWhere(
          (p) => p.nowMoving == true,
      orElse: () => _activePlayers.isNotEmpty ? _activePlayers.first : room.players.first,
    );

    if (currentPlayer.userId != _currentTurnPlayerId) {
      _handleTurnChanged(currentPlayer.userId);
    }

    // Update dice state
    if (room.rolledNumber != null && room.rolledNumber != _diceNumber) {
      _handleDiceRolled(room.rolledNumber!);
    } else if (room.rolledNumber == null && _diceRolled) {
      _resetTurnState();
    }

    notifyListeners();
  }

  void _initializeTurnSystem() {
    if (_activePlayers.isEmpty) return;

    // Find current turn player or start with first player
    final currentPlayer = _currentRoom?.players.firstWhere(
          (p) => p.nowMoving == true,
      orElse: () => _activePlayers.first,
    );

    if (currentPlayer != null) {
      _currentTurnPlayerId = currentPlayer.userId;
      _currentTurnIndex = _activePlayers.indexWhere((p) => p.userId == currentPlayer.userId);
      if (_currentTurnIndex == -1) _currentTurnIndex = 0;
    } else {
      _currentTurnPlayerId = _activePlayers.first.userId;
      _currentTurnIndex = 0;
    }

    _isMyTurn = _currentTurnPlayerId == _myPlayerId;
    _startTurnTimer();

    print('🎯 Turn system initialized: ${currentTurnPlayer?.name} (${currentTurnPlayer?.color})');
  }

  void _handleDiceRolled(int diceNumber) {
    print('🎲 Dice rolled: $diceNumber');

    _diceNumber = diceNumber;
    _diceRolled = true;
    _isDiceRolling = false;
    _waitingForMove = true;

    _updateMovablePawns();

    // Auto-skip turn if no movable pawns
    if (_isMyTurn && _movablePawns.isEmpty) {
      print('🚫 No movable pawns - auto skipping turn');
      Timer(Duration(seconds: 2), () {
        _nextTurn();
      });
    }

    notifyListeners();
  }

  void _handleTurnChanged(String playerId) {
    print('🔄 Turn changed to: $playerId');

    _currentTurnPlayerId = playerId;
    _currentTurnIndex = _activePlayers.indexWhere((p) => p.userId == playerId);
    if (_currentTurnIndex == -1) _currentTurnIndex = 0;

    _isMyTurn = playerId == _myPlayerId;
    _resetTurnState();
    _startTurnTimer();

    print('✅ Turn updated: ${currentTurnPlayer?.name} (isMyTurn: $_isMyTurn)');
    notifyListeners();
  }

  void _handlePawnMoved(Pawn pawn, int fromPos, int toPos) {
    print('🚀 Pawn moved: ${pawn.id} from $fromPos to $toPos');

    // Update local pawns list
    final pawnIndex = _pawns.indexWhere((p) => p.id == pawn.id);
    if (pawnIndex != -1) {
      _pawns[pawnIndex] = pawn;
    }

    _waitingForMove = false;

    // Check if turn should continue (rolled 6) or end
    if (_diceNumber == 6 && _isMyTurn) {
      // Continue turn - reset dice but keep turn
      _diceNumber = null;
      _diceRolled = false;
      _movablePawns.clear();
      print('🎲 Rolled 6 - continuing turn');
    } else {
      // End turn
      Timer(Duration(milliseconds: 500), () {
        _nextTurn();
      });
    }

    notifyListeners();
  }

  void _handleGameWinner(String winner) {
    print('🏆 Game winner: $winner');
    _turnTimer?.cancel();
    // Handle game end UI
    notifyListeners();
  }

  void _updateMovablePawns() {
    if (!_isMyTurn || _diceNumber == null) {
      _movablePawns.clear();
      return;
    }

    final myPawns = _pawns.where((pawn) =>
    pawn.color == myPlayer?.color
    ).toList();

    _movablePawns = myPawns.where((pawn) {
      return _canPawnMove(pawn, _diceNumber!);
    }).toList();

    print('🚀 Updated movable pawns: ${_movablePawns.length}');
  }

  bool _canPawnMove(Pawn pawn, int diceNumber) {
    // If pawn is at base, can only move with 1 or 6
    if (pawn.position == pawn.basePos) {
      return diceNumber == 1 || diceNumber == 6;
    }

    // Check if move would exceed finish line
    final maxPosition = _getMaxPositionForColor(pawn.color);
    return pawn.position + diceNumber <= maxPosition;
  }

  int _getMaxPositionForColor(String color) {
    switch (color.toLowerCase()) {
      case 'red': return 73;
      case 'blue': return 79;
      case 'green': return 85;
      case 'yellow': return 91;
      default: return 73;
    }
  }

  int _getPlayerOrder(String color) {
    switch (color.toLowerCase()) {
      case 'red': return 0;
      case 'blue': return 1;
      case 'green': return 2;
      case 'yellow': return 3;
      default: return 0;
    }
  }

  void _nextTurn() {
    if (_activePlayers.isEmpty) return;

    _currentTurnIndex = (_currentTurnIndex + 1) % _activePlayers.length;
    final nextPlayer = _activePlayers[_currentTurnIndex];

    print('⏭️ Moving to next turn: ${nextPlayer.name}');

    // Emit turn change to server
    socketService.socket.emit('game:turn', nextPlayer.userId);
  }

  void _resetTurnState() {
    _diceNumber = null;
    _diceRolled = false;
    _isDiceRolling = false;
    _waitingForMove = false;
    _movablePawns.clear();
    _remainingTime = 30;
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _remainingTime = 30;

    _turnTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _remainingTime--;
      notifyListeners();

      if (_remainingTime <= 0) {
        _turnTimer?.cancel();
        if (_isMyTurn) {
          print('⏰ Turn timeout - auto skipping');
          _nextTurn();
        }
      }
    });
  }

  // Public Methods
  void rollDice() {
    if (!canRollDice) {
      print('🚫 Cannot roll dice - conditions not met');
      return;
    }

    print('🎲 Rolling dice...');
    _isDiceRolling = true;
    notifyListeners();

    socketService.rollDice();

    // Timeout for rolling state
    Timer(Duration(seconds: 5), () {
      if (_isDiceRolling) {
        _isDiceRolling = false;
        notifyListeners();
      }
    });
  }

  void movePawn(String pawnId) {
    if (!canMovePawns) {
      print('🚫 Cannot move pawn - conditions not met');
      return;
    }

    final pawn = _pawns.firstWhere(
          (p) => p.id == pawnId,
      orElse: () => throw Exception('Pawn not found'),
    );

    if (!_movablePawns.contains(pawn)) {
      print('🚫 Pawn is not movable');
      return;
    }

    print('🚀 Moving pawn: $pawnId');
    socketService.movePawn(pawnId);
  }

  void forceNextTurn() {
    if (_isMyTurn) {
      _nextTurn();
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }
}

// Enhanced UI Components

class ModernDiceWidget extends StatefulWidget {
  final GameController gameController;

  const ModernDiceWidget({
    super.key,
    required this.gameController,
  });

  @override
  State<ModernDiceWidget> createState() => _ModernDiceWidgetState();
}

class _ModernDiceWidgetState extends State<ModernDiceWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rollController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rollAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _rollController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rollAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(ModernDiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.gameController.canRollDice) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.gameController.isDiceRolling) {
      _rollController.repeat();
    } else {
      _rollController.stop();
      _rollController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rollAnimation]),
      builder: (context, child) {
        final canRoll = widget.gameController.canRollDice;
        final isRolling = widget.gameController.isDiceRolling;
        final diceNumber = widget.gameController.diceNumber ?? 1;

        return GestureDetector(
          onTap: canRoll ? widget.gameController.rollDice : null,
          child: Transform.scale(
            scale: canRoll ? _pulseAnimation.value : 1.0,
            child: Transform.rotate(
              angle: isRolling ? _rollAnimation.value * 6.28 : 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: canRoll ? Colors.green : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canRoll ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: canRoll ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ] : [],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        isRolling ? '?' : diceNumber.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (canRoll)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlayerTurnIndicator extends StatelessWidget {
  final GameController gameController;

  const PlayerTurnIndicator({
    super.key,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameController.currentTurnPlayer;
    final isMyTurn = gameController.isMyTurn;
    final remainingTime = gameController.remainingTime;

    if (currentPlayer == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isMyTurn ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
        border: Border.all(
          color: isMyTurn ? Colors.green : Colors.blue,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Player avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorFromString(currentPlayer.color),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                currentPlayer.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyTurn ? 'Your Turn' : '${currentPlayer.name}\'s Turn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isMyTurn ? Colors.green : Colors.blue,
                  ),
                ),
                Text(
                  'Color: ${currentPlayer.color}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Timer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: remainingTime <= 5 ? Colors.red : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${remainingTime}s',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(width: 8),

          // Dice
          if (isMyTurn)
            ModernDiceWidget(gameController: gameController),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      default: return Colors.grey;
    }
  }
}

class GameStatusBar extends StatelessWidget {
  final GameController gameController;

  const GameStatusBar({
    super.key,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    final diceRolled = gameController.diceRolled;
    final canMovePawns = gameController.canMovePawns;
    final movablePawns = gameController.movablePawns;

    String statusText = '';
    Color statusColor = Colors.grey;

    if (gameController.isMyTurn) {
      if (!diceRolled) {
        statusText = 'Tap dice to roll';
        statusColor = Colors.green;
      } else if (canMovePawns) {
        statusText = 'Choose a pawn to move (${movablePawns.length} available)';
        statusColor = Colors.orange;
      } else {
        statusText = 'No moves available - turn will skip';
        statusColor = Colors.red;
      }
    } else {
      final currentPlayer = gameController.currentTurnPlayer;
      statusText = 'Waiting for ${currentPlayer?.name ?? 'opponent'}...';
      statusColor = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}