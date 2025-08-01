import 'package:flutter/material.dart';
import '../models/main_player_model.dart';
import '../models/player.dart';
import '../models/room.dart';
import 'dart:math' as math;

/// Enhanced GameProvider with proper flow handling and state management
class GameProvider with ChangeNotifier {
  // ===== CORE STATE =====
  Room? _currentRoom;
  Player? _currentPlayer;
  List<Room> _rooms = [];
  String? _error;
  bool _isLoading = false;

  // ===== GAME STATE =====
  String? _currentTurnPlayerId;
  int? _diceValue;
  int? _lastDiceNumber;
  bool _isRolling = false;
  bool _isGameStarted = false;
  bool _isGamePaused = false;
  String? _gameWinner;
  DateTime? _turnStartTime;
  int _turnTimeLimit = 30; // seconds

  // ===== GAME DATA =====
  Map<String, String> _pawnPositions = {}; // pawnId -> positionId
  Map<String, int> _playerScores = {}; // playerId -> score
  Map<String, int> _diceRollHistory = {}; // playerId -> roll count
  Map<String, int> _pawnsInHome = {}; // playerId -> pawns in home
  Map<String, List<String>> _playerMoves = {}; // playerId -> move history

  static const List<String> _availableColors = ['red', 'blue', 'green', 'yellow'];
  static const List<String> _homePositions = ['BF', 'RF', 'GF', 'YF'];

  // ===== GETTERS =====
  Room? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  List<Room> get rooms => _rooms;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Game State Getters
  String? get currentTurnPlayerId => _currentTurnPlayerId;
  int? get diceValue => _diceValue;
  int? get lastDiceNumber => _lastDiceNumber;
  bool get isRolling => _isRolling;
  bool get isGameStarted => _isGameStarted;
  bool get isGamePaused => _isGamePaused;
  String? get gameWinner => _gameWinner;
  DateTime? get turnStartTime => _turnStartTime;
  int get turnTimeLimit => _turnTimeLimit;

  Map<String, String> get pawnPositions => Map.unmodifiable(_pawnPositions);
  Map<String, int> get playerScores => Map.unmodifiable(_playerScores);

  int get remainingTurnTime {
    if (_turnStartTime == null) return _turnTimeLimit;
    final elapsed = DateTime.now().difference(_turnStartTime!).inSeconds;
    return math.max(0, _turnTimeLimit - elapsed);
  }

  // ===== COMPUTED PROPERTIES =====

  /// Checks if it's the current player's turn
  bool get isMyTurn {
    if (_currentRoom == null || _currentPlayer == null) return false;

    final movingPlayer = _currentRoom!.players.firstWhere(
          (player) => player.nowMoving,
      orElse: () => Player(
          playerId: '',
          name: '',
          color: 'red',
          ready: false,
          sessionId: '',
          userId: '', id: ''
      ),
    );

    return movingPlayer.userId == _currentPlayer!.userId;
  }

  void updateRoomList(List<Room> rooms) {
    _rooms = rooms;
    notifyListeners();
  }

  // Set winner
  void setWinner(String winnerColor) {
    _gameWinner = winnerColor;
    notifyListeners();
  }

  /// Gets the current turn player's color
  String? get currentTurnColor {
    if (_currentRoom == null) return null;

    try {
      return _currentRoom!.players
          .firstWhere((player) => player.nowMoving)
          .color.toString();
    } catch (e) {
      return null;
    }
  }

  /// Gets the current turn player
  Player? get currentTurnPlayer {
    if (_currentRoom == null) return null;

    try {
      return _currentRoom!.players.firstWhere((player) => player.nowMoving);
    } catch (e) {
      return null;
    }
  }

  /// Gets the current turn player's name
  String? get currentTurnPlayerName => currentTurnPlayer?.name;

  // ===== SESSION MANAGEMENT =====

  /// Sets player data from session
  void setPlayerData(Map<String, dynamic> data) {
    _currentPlayer = Player(id: data['_id'],
      playerId: data['playerId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      name: data['playerName'] ?? data['name'] ?? '',
      color: data['color'] ?? '',
      userId: data['userId'] ?? '',
      ready: data['ready'] ?? false,
      nowMoving: data['nowMoving'] ?? false,
    );
    _clearError();
    notifyListeners();
  }

  /// Sets player directly
  void setPlayer(Player player) {
    _currentPlayer = player;
    notifyListeners();
  }

  /// Initializes player for a room
  void initializePlayer(String userId, Room room) {
    _currentPlayer = room.players.firstWhere(
          (p) => p.userId == userId,
      orElse: () => Player(
        playerId: 'temp-$userId',
        userId: userId,
        name: 'Player',
        color:'red',
        ready: false,
        id: '',
        sessionId: '',
      ),
    );
    notifyListeners();
  }

  // ===== ROOM MANAGEMENT =====

  /// Creates a new game room
  void createNewRoom(Room room) {
    _currentRoom = room;
    _rooms.add(room);
    _clearError();
    _resetGameState();
    notifyListeners();

    debugPrint('🏠 Room created: ${room.id}');
  }

  /// Joins an existing room
  void joinRoom(Room room) {
    _currentRoom = room;
    _clearError();
    notifyListeners();

    debugPrint('🚪 Joined room: ${room.id}');
  }

  /// Updates room data (for real-time updates)
  void updateRoom(Room room) {
    _currentRoom = room;

    // Update the room in the rooms list if it exists
    final roomIndex = _rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      _rooms[roomIndex] = room;
    }

    notifyListeners();
    debugPrint('🔄 Room updated: ${room.id}');
  }

  /// Leaves the current room
  void leaveRoom() {
    debugPrint('🚪 Left room: ${_currentRoom?.id}');
    _currentRoom = null;
    _currentPlayer = null;
    _clearError();
    _resetGameState();
    notifyListeners();
  }

  /// Sets the rooms list
  void setRooms(List<Room> rooms) {
    _rooms = rooms;
    notifyListeners();
  }

  // ===== PLAYER MANAGEMENT =====

  /// Adds a player to the current room
  void addPlayerToRoom(Player player) {
    if (_currentRoom != null) {
      final existingIndex = _currentRoom!.players.indexWhere((p) => p.userId == player.userId);
      if (existingIndex != -1) {
        _currentRoom!.players[existingIndex] = player;
      } else {
        _currentRoom!.players.add(player);
      }
      notifyListeners();
      debugPrint('👤 Player added to room: ${player.name}');
    }
  }

  /// Updates a player's ready status
  void updatePlayerReady(String playerId, bool ready) {
    if (_currentRoom != null) {
      final playerIndex = _currentRoom!.players.indexWhere((p) => p.userId == playerId);
      if (playerIndex != -1) {
        _currentRoom!.players[playerIndex].ready = ready;
        notifyListeners();
      }
    }

    if (_currentPlayer?.userId == playerId) {
      _currentPlayer!.ready = ready;
      notifyListeners();
    }

    debugPrint('✅ Player ready status updated: $playerId -> $ready');
  }

  /// Removes a player from the room
  void removePlayerFromRoom(String playerId) {
    if (_currentRoom != null) {
      _currentRoom!.players.removeWhere((p) => p.userId == playerId);
      notifyListeners();
      debugPrint('❌ Player removed from room: $playerId');
    }
  }

  /// Gets a player by their color
  Player? getPlayerByColor(String color) {
    if (_currentRoom == null) return null;
    try {
      return _currentRoom!.players.firstWhere(
              (p) => p.color.toString().toLowerCase() == color.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Checks if a specific color player's turn
  bool isPlayerTurn(String color) {
    return _currentRoom != null &&
        _currentRoom!.players.any((p) =>
        p.color.toString() == color && p.nowMoving
        );
  }

  // ===== GAME FLOW MANAGEMENT =====

  /// Starts the game
  void startGame(Room room) {
    _currentRoom = room;
    _isGameStarted = true;
    _isGamePaused = false;
    _gameWinner = null;
    _clearError();

    // Initialize game state
    _initializeGameState();

    notifyListeners();
    debugPrint('🎮 Game started in room: ${room.id}');
  }

  /// Pauses the game
  void pauseGame() {
    _isGamePaused = true;
    notifyListeners();
    debugPrint('⏸️ Game paused');
  }

  /// Resumes the game
  void resumeGame() {
    _isGamePaused = false;
    _turnStartTime = DateTime.now(); // Reset turn timer
    notifyListeners();
    debugPrint('▶️ Game resumed');
  }

  /// Ends the game with a winner
  void endGame(String winnerColor) {
    _gameWinner = winnerColor;
    _currentTurnPlayerId = null;
    _isGameStarted = false;
    notifyListeners();
    debugPrint('🏆 Game ended. Winner: $winnerColor');
  }

  // ===== TURN MANAGEMENT =====

  /// Sets the current turn to a specific player
  void setCurrentTurn(String playerId) {
    _currentTurnPlayerId = playerId;
    _turnStartTime = DateTime.now();
    _lastDiceNumber = null; // Reset dice for new turn
    _diceValue = null;
    notifyListeners();
    debugPrint('🔄 Turn changed to player: $playerId');
  }

  /// Starts a player's turn
  void startPlayerTurn(String playerId) {
    setCurrentTurn(playerId);
  }

  /// Ends the current player's turn
  void endPlayerTurn() {
    _lastDiceNumber = null;
    _diceValue = null;
    _isRolling = false;
    notifyListeners();
    debugPrint('⏹️ Turn ended for player: $_currentTurnPlayerId');
  }

  // ===== DICE MANAGEMENT =====

  /// Updates dice roll with animation
  void updateDiceRoll(int value) {
    _lastDiceNumber = value;
    _diceValue = value;
    _isRolling = true;

    // Update dice roll history
    final currentPlayer = _currentTurnPlayerId ?? 'unknown';
    _diceRollHistory[currentPlayer] = (_diceRollHistory[currentPlayer] ?? 0) + 1;

    notifyListeners();

    // Stop rolling animation after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_isRolling) {
        _isRolling = false;
        notifyListeners();
      }
    });

    debugPrint('🎲 Dice rolled: $value by player: $currentPlayer');
  }

  /// Legacy method for compatibility
  void setDiceRoll(int value) {
    updateDiceRoll(value);
  }

  /// Resets the turn dice
  void resetTurn() {
    _lastDiceNumber = null;
    _diceValue = null;
    _isRolling = false;
    notifyListeners();
  }

  // ===== PAWN MANAGEMENT =====

  /// Updates a pawn's position
  void updatePawnPosition(String pawnId, String newPosition) {
    final oldPosition = _pawnPositions[pawnId] ?? 'home';
    _pawnPositions[pawnId] = newPosition;

    // Track move history
    final playerId = _getPlayerIdFromPawnId(pawnId);
    if (playerId != null) {
      _playerMoves[playerId] ??= [];
      _playerMoves[playerId]!.add('$pawnId: $oldPosition -> $newPosition');

      // Update pawns in home count
      if (_isHomePosition(newPosition)) {
        _pawnsInHome[playerId] = (_pawnsInHome[playerId] ?? 0) + 1;

        // Check for win condition
        if (_pawnsInHome[playerId] == 4) {
          final winner = getPlayerByColor(_getPawnColorFromId(pawnId));
          if (winner != null) {
            endGame(winner.color.toString());
          }
        }
      }
    }

    notifyListeners();
    debugPrint('♟️ Pawn $pawnId moved from $oldPosition to $newPosition');
  }

  /// Moves pawn to a specific position
  void movePawnToPosition(String pawnId, String newPosition) {
    updatePawnPosition(pawnId, newPosition);
  }

  /// Gets the number of pawns at home for a color
  int getPawnsAtHome(String color) {
    if (_currentRoom == null) return 4;

    try {
      return _currentRoom!.pawns.where((pawn) {
        return pawn.color == color && pawn.position == pawn.basePos;
      }).length;
    } catch (e) {
      return 4;
    }
  }

  // ===== GAME VALIDATION =====

  /// Checks if the current player can roll dice
  bool canRollDice() {
    return isMyTurn &&
        !_isRolling &&
        !_isGamePaused &&
        _gameWinner == null &&
        _isGameStarted;
  }

  /// Checks if a pawn can be moved
  bool canMovePawn(String pawnId) {
    if (!isMyTurn || _isGamePaused || _gameWinner != null) {
      return false;
    }

    // Must have rolled dice first
    if (_lastDiceNumber == null || _lastDiceNumber == 0) {
      return false;
    }

    // Check if pawn belongs to current player
    if (!_isPawnOwnedByCurrentPlayer(pawnId)) {
      return false;
    }

    return _isValidPawnMove(pawnId, _lastDiceNumber!);
  }

  /// Validates if a move is legal
  bool isValidMove(String pawnId, String fromPosition, String toPosition) {
    if (_lastDiceNumber == null) return false;
    return _pawnPositions[pawnId] == fromPosition;
  }

  /// Validates a move and returns error message if invalid
  String? validateMove(String pawnId, String fromPosition, String toPosition) {
    if (!canMovePawn(pawnId)) {
      return 'Cannot move this pawn right now';
    }

    if (_pawnPositions[pawnId] != fromPosition) {
      return 'Pawn is not at the expected position';
    }

    if (_lastDiceNumber == null) {
      return 'Must roll dice first';
    }

    return null; // Valid move
  }

  /// Checks if the game state is valid
  bool isValidGameState() {
    return _currentRoom != null &&
        _currentRoom!.players.isNotEmpty &&
        _isGameStarted;
  }

  // ===== GAME STATE UPDATES =====

  /// Updates the complete game state from server
  void updateGameState(Map<String, dynamic> gameState) {
    try {
      bool shouldNotify = false;

      // Update current turn
      if (gameState.containsKey('currentTurn') &&
          gameState['currentTurn'] != _currentTurnPlayerId) {
        _currentTurnPlayerId = gameState['currentTurn'];
        _turnStartTime = DateTime.now();
        shouldNotify = true;
      }

      // Update dice roll
      if (gameState.containsKey('lastDiceRoll')) {
        final newDiceValue = gameState['lastDiceRoll'];
        if (newDiceValue != _lastDiceNumber) {
          _lastDiceNumber = newDiceValue;
          _diceValue = newDiceValue;
          shouldNotify = true;
        }
      }

      // Update pawn positions
      if (gameState.containsKey('pawnPositions')) {
        final newPositions = Map<String, String>.from(gameState['pawnPositions']);
        if (!_mapsEqual(_pawnPositions, newPositions)) {
          _pawnPositions = newPositions;
          shouldNotify = true;
        }
      }

      // Update player scores
      if (gameState.containsKey('playerScores')) {
        final newScores = Map<String, int>.from(gameState['playerScores']);
        if (!_mapsEqual(_playerScores, newScores)) {
          _playerScores = newScores;
          shouldNotify = true;
        }
      }

      // Update game status
      if (gameState.containsKey('isPaused')) {
        final isPaused = gameState['isPaused'] as bool;
        if (isPaused != _isGamePaused) {
          _isGamePaused = isPaused;
          shouldNotify = true;
        }
      }

      // Update winner
      if (gameState.containsKey('winner') && gameState['winner'] != null) {
        final winner = gameState['winner'] as String;
        if (winner != _gameWinner) {
          _gameWinner = winner;
          shouldNotify = true;
        }
      }

      if (shouldNotify) {
        notifyListeners();
      }

    } catch (e) {
      debugPrint('❌ Error updating game state: $e');
      setError('Failed to update game state');
    }
  }

  // ===== STATISTICS & ANALYTICS =====

  /// Gets comprehensive game statistics
  Map<String, dynamic> getGameStatistics() {
    return {
      'diceRollHistory': _diceRollHistory,
      'pawnsInHome': _pawnsInHome,
      'playerMoves': _playerMoves,
      'totalMoves': _playerMoves.values.fold(0, (sum, moves) => sum + moves.length),
      'gameWinner': _gameWinner,
      'gameDuration': _turnStartTime != null
          ? DateTime.now().difference(_turnStartTime!).inMinutes
          : 0,
    };
  }

  /// Gets player statistics for all players
  Map<String, PlayerGameStats> getPlayerStats() {
    final stats = <String, PlayerGameStats>{};

    for (final player in _currentRoom?.players ?? []) {
      final playerId = player.id;
      final pawnsAtHome = _pawnsInHome[playerId] ?? 0;
      final diceRolls = _diceRollHistory[playerId] ?? 0;
      final moves = _playerMoves[playerId]?.length ?? 0;

      stats[player.color] = PlayerGameStats(
        playerId: playerId,
        playerName: player.name,
        color: player.color,
        pawnsAtHome: pawnsAtHome,
        pawnsOnBoard: _countPawnsOnBoard(playerId),
        totalDiceRolls: diceRolls,
        totalMoves: moves,
        nowMoving: playerId == _currentTurnPlayerId,
      );
    }

    return stats;
  }

  /// Gets move history for a specific player
  List<String> getPlayerMoveHistory(String playerId) {
    return _playerMoves[playerId] ?? [];
  }

  /// Gets dice roll count for a specific player
  int getPlayerDiceRollCount(String playerId) {
    return _diceRollHistory[playerId] ?? 0;
  }

  /// Gets pawns in home count for a specific player
  int getPlayerPawnsInHome(String playerId) {
    return _pawnsInHome[playerId] ?? 0;
  }

  // ===== ERROR HANDLING =====

  /// Sets an error message with auto-clear
  void setError(String message) {
    _error = message;
    notifyListeners();

    Future.delayed(const Duration(seconds: 5), () {
      if (_error == message) {
        _error = null;
        notifyListeners();
      }
    });
  }

  /// Clears the current error
  void clearError() {
    _clearError();
  }

  void _clearError() {
    _error = null;
  }

  // ===== LOADING STATE =====

  /// Sets the loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ===== RESET METHODS =====

  /// Resets the entire game state
  void resetGame() {
    _currentRoom = null;
    _currentPlayer = null;
    _clearError();
    _resetGameState();
    notifyListeners();
    debugPrint('🔄 Complete game reset');
  }

  /// Resets only the game state (keeps room and players)
  void resetGameState() {
    _resetGameState();
  }

  void _resetGameState() {
    _currentTurnPlayerId = null;
    _diceValue = null;
    _lastDiceNumber = null;
    _isRolling = false;
    _isGameStarted = false;
    _isGamePaused = false;
    _gameWinner = null;
    _turnStartTime = null;
    _pawnPositions.clear();
    _playerScores.clear();
    _diceRollHistory.clear();
    _pawnsInHome.clear();
    _playerMoves.clear();
    _isLoading = false;
  }

  // ===== PRIVATE HELPER METHODS =====

  /// Initializes game state when starting a new game
  void _initializeGameState() {
    _pawnPositions.clear();
    _playerScores.clear();
    _diceRollHistory.clear();
    _pawnsInHome.clear();
    _playerMoves.clear();

    // Initialize player scores and pawn counts
    for (final player in _currentRoom?.players ?? []) {
      _playerScores[player.id] = 0;
      _pawnsInHome[player.id] = 0;
      _diceRollHistory[player.id] = 0;
      _playerMoves[player.id] = [];
    }
  }

  /// Assigns a color to a new player
  String _assignColor(Room room) {
    final usedColors = room.players.map((p) => p.color).toList();
    return _availableColors.firstWhere(
          (c) => !usedColors.contains(c),
      orElse: () => _availableColors.first,
    );
  }

  /// Checks if a pawn is owned by the current player
  bool _isPawnOwnedByCurrentPlayer(String pawnId) {
    if (_currentPlayer == null) return false;
    final playerColor = _currentPlayer!.color.toString().toLowerCase();
    final pawnColor = _getPawnColorFromId(pawnId);
    return playerColor == pawnColor;
  }

  /// Gets color from pawn ID
  String _getPawnColorFromId(String pawnId) {
    if (pawnId.isEmpty) return '';
    final firstChar = pawnId[0].toLowerCase();
    switch (firstChar) {
      case 'r': return 'red';
      case 'b': return 'blue';
      case 'g': return 'green';
      case 'y': return 'yellow';
      default: return '';
    }
  }

  /// Gets player ID from pawn ID
  String? _getPlayerIdFromPawnId(String pawnId) {
    if (pawnId.length >= 2) {
      final prefix = pawnId.substring(0, 2);
      switch (prefix) {
        case 'BP': return 'blue_player';
        case 'RP': return 'red_player';
        case 'GP': return 'green_player';
        case 'YP': return 'yellow_player';
      }
    }
    return null;
  }

  /// Checks if a position is a home position
  bool _isHomePosition(String position) {
    return _homePositions.contains(position);
  }

  /// Validates if a pawn move is legal
  bool _isValidPawnMove(String pawnId, int diceNumber) {
    final currentPosition = _pawnPositions[pawnId] ?? 'home';

    if (currentPosition == 'home') {
      return diceNumber == 6; // Can only move out of home with a 6
    }

    return true; // Simplified validation
  }

  /// Gets the owner of a pawn
  String? _getPawnOwner(String pawnId) {
    final color = _getPawnColorFromId(pawnId);
    final player = getPlayerByColor(color);
    return player?.userId;
  }

  /// Counts pawns on board for a player
  int _countPawnsOnBoard(String playerId) {
    int count = 0;
    for (final entry in _pawnPositions.entries) {
      if (_getPawnOwner(entry.key) == playerId) {
        final position = entry.value;
        if (position != 'home' && !_isHomePosition(position)) {
          count++;
        }
      }
    }
    return count;
  }

  /// Compares two maps for equality
  bool _mapsEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}


/// Statistics class for individual player game data
class PlayerGameStats {
  final String playerId;
  final String playerName;
  final String color;
  final int pawnsAtHome;
  final int pawnsOnBoard;
  final int totalDiceRolls;
  final int totalMoves;
  final bool nowMoving;

  const PlayerGameStats({
    required this.playerId,
    required this.playerName,
    required this.color,
    required this.pawnsAtHome,
    required this.pawnsOnBoard,
    required this.totalDiceRolls,
    required this.totalMoves,
    required this.nowMoving,
  });

  @override
  String toString() {
    return 'PlayerGameStats('
        'playerId: $playerId, '
        'playerName: $playerName, '
        'color: $color, '
        'pawnsAtHome: $pawnsAtHome, '
        'pawnsOnBoard: $pawnsOnBoard, '
        'totalDiceRolls: $totalDiceRolls, '
        'totalMoves: $totalMoves, '
        'nowMoving: $nowMoving'
        ')';
  }
}

/// Extension methods for better code organization
extension GameProviderHelpers on GameProvider {
  /// Quick check if all players are ready
  bool get allPlayersReady {
    if (currentRoom == null) return false;
    return currentRoom!.players.every((player) => player.ready);
  }

  /// Gets the number of players in current room
  int get playerCount => currentRoom?.players.length ?? 0;

  /// Checks if room is full (assuming max 4 players)
  bool get isRoomFull => playerCount >= 4;

  /// Gets available colors for new players
  List<String> get availableColors {
    if (currentRoom == null) return GameProvider._availableColors;
    final usedColors = currentRoom!.players.map((p) => p.color).toList();
    return GameProvider._availableColors.where((c) => !usedColors.contains(c)).toList();
  }
}