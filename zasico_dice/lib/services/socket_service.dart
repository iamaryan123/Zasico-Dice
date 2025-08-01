import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/pawn.dart';

class SocketService with ChangeNotifier {
  late IO.Socket socket;
  static const String serverUrl = 'https://d80bdd692897.ngrok-free.app';
  bool isConnected = false;
  String? currentUserId;
  String? currentPlayerName;

  // Enhanced Game State Management
  Room? currentRoom;
  List<Pawn> pawns = [];
  int? currentDiceNumber;
  String? currentTurnPlayer;
  String? myPlayerColor;
  bool isMyTurn = false;
  bool isDiceRolling = false;
  bool hasDiceBeenRolled = false;
  Timer? _diceRollTimeout;
  Timer? _turnTimeout;

  // Callback functions for UI updates
  Function(String message)? onError;
  Function(Room room)? onRoomCreated;
  Function(Room room)? onRoomJoined;
  Function(List<Room> rooms)? onRoomsReceived;
  Function(Room room)? onGameStateUpdate;
  Function(Room room)? onGameStarted;
  Function(String playerName, String color)? onPlayerJoined;
  Function()? onRoomLeft;

  // Enhanced Game-specific callbacks
  Function(int diceNumber)? onDiceRolled;
  Function(bool isRolling)? onDiceRollingStateChanged;
  Function(List<Pawn> pawns)? onPawnsUpdated;
  Function(String winner)? onGameWinner;
  Function(String currentPlayer)? onTurnChanged;
  Function(Pawn pawn, int fromPosition, int toPosition)? onPawnMoved;

  /// Connect to socket server with enhanced error handling
  Future<void> connect(String userId, String playerName) async {
    if (isConnected) return;

    currentUserId = userId;
    currentPlayerName = playerName;

    try {
      socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .enableAutoConnect()
            .setTimeout(10000)
            .setExtraHeaders({
          'userId': userId,
          'playerName': playerName,
        })
            .build(),
      );

      _setupEventListeners();
      socket.connect();

      print('🚀 Connecting socket for user: $userId ($playerName)');
    } catch (e) {
      print('❌ Socket connection error: $e');
      isConnected = false;
      if (onError != null) onError!('Failed to connect to server');
    }
  }

  /// Setup all socket event listeners with enhanced handling
  void _setupEventListeners() {
    // === CONNECTION EVENTS ===
    socket.on('connect', (_) {
      print('✅ Socket connected successfully');
      isConnected = true;
      notifyListeners();
    });

    socket.on('disconnect', (data) {
      print('❌ Socket disconnected: $data');
      isConnected = false;
      _resetGameState();
      notifyListeners();
    });

    socket.on('connect_error', (error) {
      print('❌ Connection error: $error');
      isConnected = false;
      if (onError != null) onError!('Connection failed: $error');
    });

    socket.on('reconnect', (data) {
      print('🔄 Socket reconnected');
      isConnected = true;
      Timer(Duration(seconds: 1), () => requestGameData());
      notifyListeners();
    });

    // === ROOM EVENTS ===
    socket.on('room:created', (data) => _handleRoomCreated(data));
    socket.on('room:joined', (data) => _handleRoomJoined(data));
    socket.on('room:rooms', (data) => _handleRoomsList(data));
    socket.on('room:data', (data) => _handleRoomData(data));
    socket.on('room:error', (error) => _handleRoomError(error));
    socket.on('room:left', (_) => _handleRoomLeft());

    // === ENHANCED GAME EVENTS ===
    socket.on('game:started', (data) => _handleGameStarted(data));
    socket.on('game:roll', (data) => _handleDiceRoll(data));
    socket.on('game:turn', (data) => _handleTurnChanged(data));
    socket.on('game:move', (data) => _handlePawnMoved(data));
    socket.on('game:winner', (winner) => _handleGameWinner(winner));
    socket.on('game:state', (data) => _handleGameState(data));

    // === PLAYER EVENTS ===
    socket.on('player:joined', (data) => _handlePlayerJoined(data));
    socket.on('player:left', (data) => _handlePlayerLeft(data));
  }

  // === ENHANCED GAME EVENT HANDLERS ===

  void _handleGameStarted(dynamic data) {
    try {
      print('🎯 Game started event received');

      Map<String, dynamic> gameData;
      if (data is String) {
        gameData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        gameData = data;
      } else {
        print('❌ Unexpected game started data format');
        return;
      }

      dynamic roomData = gameData['room'] ?? gameData;
      if (roomData is String) {
        roomData = jsonDecode(roomData);
      }

      final room = Room.fromJson(roomData);
      currentRoom = room;
      pawns = room.pawns;

      _updateGameState(room);
      _resetTurnState();

      print('✅ Game started: ${room.name}');
      print('   Players: ${room.players.map((p) => '${p.name}(${p.color})').join(', ')}');

      if (onGameStarted != null) onGameStarted!(room);

    } catch (e) {
      print('❌ Error handling game started: $e');
      if (onError != null) onError!('Failed to start game');
    }
  }

  void _handleDiceRoll(dynamic data) {
    try {
      final diceNumber = data is int ? data : int.parse(data.toString());

      print('🎲 Dice rolled: $diceNumber');
      print('   Current turn: $currentTurnPlayer');
      print('   My color: $myPlayerColor');
      print('   Is my turn: ${currentTurnPlayer == myPlayerColor}');

      // Update dice state
      currentDiceNumber = diceNumber;
      hasDiceBeenRolled = true;
      isDiceRolling = false;

      // Clear rolling timeout
      _diceRollTimeout?.cancel();

      // Update my turn status
      isMyTurn = currentTurnPlayer == myPlayerColor;

      // Notify UI
      if (onDiceRolled != null) onDiceRolled!(diceNumber);
      if (onDiceRollingStateChanged != null) onDiceRollingStateChanged!(false);

      print('✅ Dice state updated - Number: $diceNumber, HasRolled: $hasDiceBeenRolled');

    } catch (e) {
      print('❌ Error handling dice roll: $e');
      isDiceRolling = false;
      if (onDiceRollingStateChanged != null) onDiceRollingStateChanged!(false);
    }
  }

  void _handleTurnChanged(dynamic data) {
    try {
      final newTurnPlayer = data.toString();
      print('🔄 Turn changed to: $newTurnPlayer (from: $currentTurnPlayer)');

      final previousPlayer = currentTurnPlayer;
      currentTurnPlayer = newTurnPlayer;
      isMyTurn = newTurnPlayer == myPlayerColor;

      // Reset turn-specific state
      _resetTurnState();

      print('✅ Turn updated:');
      print('   Previous: $previousPlayer');
      print('   Current: $currentTurnPlayer');
      print('   My color: $myPlayerColor');
      print('   Is my turn: $isMyTurn');

      if (onTurnChanged != null) onTurnChanged!(newTurnPlayer);

      // Set turn timeout for safety (30 seconds)
      _turnTimeout?.cancel();
      _turnTimeout = Timer(Duration(seconds: 30), () {
        if (currentTurnPlayer == newTurnPlayer) {
          print('⏰ Turn timeout - requesting fresh game data');
          requestGameData();
        }
      });

    } catch (e) {
      print('❌ Error handling turn change: $e');
    }
  }

  void _handleRoomData(dynamic data) {
    try {
      print('📊 Room data update received');
      final roomData = data is String ? jsonDecode(data) : data;
      final room = Room.fromJson(roomData);

      // Update current room
      currentRoom = room;
      pawns = room.pawns;

      // Update game state
      _updateGameState(room);

      print('🎮 Game state updated:');
      print('   Players: ${room.players.length}');
      print('   Pawns: ${room.pawns.length}');
      print('   Current turn: $currentTurnPlayer');
      print('   My color: $myPlayerColor');
      print('   Is my turn: $isMyTurn');
      print('   Dice: $currentDiceNumber');
      print('   Dice rolled: $hasDiceBeenRolled');

      // Notify UI
      if (onGameStateUpdate != null) onGameStateUpdate!(room);
      if (onPawnsUpdated != null) onPawnsUpdated!(pawns);

    } catch (e) {
      print('❌ Error parsing room data: $e');
      // Request fresh data after error
      Timer(Duration(seconds: 2), () => requestGameData());
    }
  }

  void _handleRoomCreated(dynamic data) {
    try {
      print('🏠 Room created event: $data');
      final roomData = data is String ? jsonDecode(data) : data;

      if (roomData['success'] == true) {
        final room = Room.fromJson(jsonDecode(roomData['room']));
        currentRoom = room;
        _updateMyPlayerInfo();
        if (onRoomCreated != null) onRoomCreated!(room);
      } else {
        if (onError != null) onError!(roomData['message'] ?? 'Failed to create room');
      }
    } catch (e) {
      print('❌ Error parsing room created: $e');
      if (onError != null) onError!('Failed to create room');
    }
  }

  void _handleRoomJoined(dynamic data) {
    try {
      print('🚪 Room joined event: $data');
      final roomData = data['room'] is String
          ? jsonDecode(data['room'])
          : data['room'];

      final room = Room.fromJson(roomData);
      currentRoom = room;
      _updateMyPlayerInfo();

      if (onRoomJoined != null) onRoomJoined!(room);
    } catch (e) {
      print('❌ Error parsing room joined: $e');
      if (onError != null) onError!('Failed to join room');
    }
  }

  void _handleRoomsList(dynamic data) {
    try {
      print('📋 Rooms list received');
      final roomsData = data is String ? jsonDecode(data) : data;
      final rooms = (roomsData as List)
          .map((r) => Room.fromJson(r))
          .toList();

      if (onRoomsReceived != null) onRoomsReceived!(rooms);
    } catch (e) {
      print('❌ Error parsing rooms: $e');
      if (onError != null) onError!('Failed to fetch rooms');
    }
  }

  void _handleRoomError(dynamic error) {
    print('❌ Room error: $error');
    if (onError != null) {
      onError!(error['message'] ?? 'Room error occurred');
    }
  }

  void _handleRoomLeft() {
    print('👋 Left room successfully');
    _resetGameState();
    if (onRoomLeft != null) onRoomLeft!();
  }

  void _handlePawnMoved(dynamic data) {
    try {
      print('🚀 Pawn moved: $data');

      // Update pawns list and request fresh game data
      requestGameData();

      // If data contains move details, notify UI
      if (onPawnMoved != null && data is Map) {
        final pawnId = data['pawnId'];
        final fromPos = data['fromPosition'];
        final toPos = data['toPosition'];

        final pawn = pawns.firstWhere((p) => p.id == pawnId, orElse: () => pawns.first);
        if (fromPos != null && toPos != null) {
          onPawnMoved!(pawn, fromPos, toPos);
        }
      }

    } catch (e) {
      print('❌ Error handling pawn move: $e');
    }
  }

  void _handleGameState(dynamic data) {
    try {
      print('🎮 Game state update: $data');
      final stateData = data is String ? jsonDecode(data) : data;

      // Update current turn and dice state
      if (stateData['currentTurn'] != null) {
        currentTurnPlayer = stateData['currentTurn'];
        isMyTurn = currentTurnPlayer == myPlayerColor;
      }

      if (stateData['diceNumber'] != null) {
        currentDiceNumber = stateData['diceNumber'];
        hasDiceBeenRolled = true;
      } else {
        currentDiceNumber = null;
        hasDiceBeenRolled = false;
      }

    } catch (e) {
      print('❌ Error handling game state: $e');
    }
  }

  void _handleGameWinner(dynamic winner) {
    try {
      final winnerColor = winner.toString();
      print('🏆 Game winner: $winnerColor');

      if (onGameWinner != null) onGameWinner!(winnerColor);

    } catch (e) {
      print('❌ Error handling game winner: $e');
    }
  }

  void _handlePlayerJoined(dynamic data) {
    try {
      final playerName = data['playerName']?.toString() ?? '';
      final playerColor = data['playerColor']?.toString() ?? '';

      print('👤 Player joined: $playerName ($playerColor)');

      // Request updated room data
      Timer(Duration(milliseconds: 500), () => requestGameData());

      if (onPlayerJoined != null) onPlayerJoined!(playerName, playerColor);

    } catch (e) {
      print('❌ Error handling player joined: $e');
    }
  }

  void _handlePlayerLeft(dynamic data) {
    try {
      print('👋 Player left: $data');

      // Request updated room data
      Timer(Duration(milliseconds: 500), () => requestGameData());

    } catch (e) {
      print('❌ Error handling player left: $e');
    }
  }

  // === ENHANCED HELPER METHODS ===

  void _updateMyPlayerInfo() {
    if (currentRoom == null || currentUserId == null) return;

    try {
      final myPlayer = currentRoom!.players.firstWhere(
            (p) => p.userId == currentUserId || p.name == currentPlayerName,
        orElse: () => currentRoom!.players.first,
      );

      myPlayerColor = myPlayer.color;
      print('👤 My player updated: $myPlayerColor');

    } catch (e) {
      print('❌ Error updating my player info: $e');
    }
  }

  void _updateGameState(Room room) {
    // Find current turn player
    try {
      final currentPlayer = room.players.firstWhere(
            (p) => p.nowMoving == true,
        orElse: () => room.players.first,
      );

      final previousTurnPlayer = currentTurnPlayer;
      currentTurnPlayer = currentPlayer.color;
      isMyTurn = currentTurnPlayer == myPlayerColor;

      // Update dice state from room data
      final previousDiceNumber = currentDiceNumber;
      currentDiceNumber = room.rolledNumber;
      hasDiceBeenRolled = currentDiceNumber != null;

      // Log state changes
      if (previousTurnPlayer != currentTurnPlayer) {
        print('🔄 Turn changed in state update: $previousTurnPlayer -> $currentTurnPlayer');
      }

      if (previousDiceNumber != currentDiceNumber) {
        print('🎲 Dice updated in state: $previousDiceNumber -> $currentDiceNumber');
      }

      print('📊 Game state synchronized:');
      print('   Current player: $currentTurnPlayer');
      print('   My color: $myPlayerColor');
      print('   Is my turn: $isMyTurn');
      print('   Dice number: $currentDiceNumber');
      print('   Has rolled: $hasDiceBeenRolled');

    } catch (e) {
      print('❌ Error updating game state: $e');
    }
  }

  void _resetTurnState() {
    print('🔄 Resetting turn state');
    currentDiceNumber = null;
    hasDiceBeenRolled = false;
    isDiceRolling = false;
    _diceRollTimeout?.cancel();
    _turnTimeout?.cancel();
  }

  void _resetGameState() {
    print('🔄 Resetting game state');
    currentRoom = null;
    pawns.clear();
    currentDiceNumber = null;
    currentTurnPlayer = null;
    myPlayerColor = null;
    isMyTurn = false;
    hasDiceBeenRolled = false;
    isDiceRolling = false;
    _diceRollTimeout?.cancel();
    _turnTimeout?.cancel();
  }

  /// Enhanced dice rolling with comprehensive validation
  void rollDice() {
    print('🎲 Attempting to roll dice...');
    print('   Connected: $isConnected');
    print('   My turn: $isMyTurn');
    print('   Current turn: $currentTurnPlayer');
    print('   My color: $myPlayerColor');
    print('   Has rolled: $hasDiceBeenRolled');
    print('   Is rolling: $isDiceRolling');

    if (!isConnected) {
      print('❌ Cannot roll dice: Socket not connected');
      if (onError != null) onError!('Not connected to server');
      return;
    }

    if (currentTurnPlayer != myPlayerColor) {
      print('❌ Cannot roll dice: Not your turn (Current: $currentTurnPlayer, Me: $myPlayerColor)');
      if (onError != null) onError!('Not your turn! Current turn: $currentTurnPlayer');
      return;
    }

    if (!isMyTurn) {
      print('❌ Cannot roll dice: isMyTurn flag is false');
      if (onError != null) onError!('Not your turn!');
      return;
    }

    if (hasDiceBeenRolled) {
      print('❌ Cannot roll dice: Already rolled this turn');
      if (onError != null) onError!('You already rolled the dice this turn!');
      return;
    }

    if (isDiceRolling) {
      print('❌ Cannot roll dice: Already rolling');
      return;
    }

    print('✅ Rolling dice - All validations passed');

    // Set rolling state
    isDiceRolling = true;
    if (onDiceRollingStateChanged != null) onDiceRollingStateChanged!(true);

    // Set timeout for rolling animation (with longer timeout for server response)
    _diceRollTimeout = Timer(Duration(seconds: 10), () {
      if (isDiceRolling) {
        print('⏰ Dice roll timeout - stopping animation and requesting fresh data');
        isDiceRolling = false;
        if (onDiceRollingStateChanged != null) onDiceRollingStateChanged!(false);
        // Request fresh data in case we missed the response
        requestGameData();
      }
    });

    // Send roll request
    try {
      socket.emit('game:roll');
      print('📤 Dice roll request sent to server');
    } catch (e) {
      print('❌ Error sending dice roll: $e');
      isDiceRolling = false;
      if (onDiceRollingStateChanged != null) onDiceRollingStateChanged!(false);
      if (onError != null) onError!('Failed to roll dice');
    }
  }

  /// Enhanced pawn movement with validation
  void movePawn(String pawnId) {
    if (!isConnected) {
      print('❌ Cannot move pawn: Socket not connected');
      return;
    }

    if (!isMyTurn) {
      print('❌ Cannot move pawn: Not your turn');
      return;
    }

    if (!hasDiceBeenRolled || currentDiceNumber == null) {
      print('❌ Cannot move pawn: No dice rolled');
      return;
    }

    final pawn = getPawnById(pawnId);
    if (pawn == null) {
      print('❌ Cannot move pawn: Pawn not found');
      return;
    }

    if (pawn.color != myPlayerColor) {
      print('❌ Cannot move pawn: Not your pawn');
      return;
    }

    if (!canPawnMove(pawn, currentDiceNumber!)) {
      print('❌ Cannot move pawn: Invalid move');
      return;
    }

    print('🚀 Moving pawn: $pawnId');
    socket.emit('game:move', pawnId);
  }

  /// Get pawn by ID
  Pawn? getPawnById(String pawnId) {
    try {
      return pawns.firstWhere((pawn) => pawn.id == pawnId);
    } catch (e) {
      return null;
    }
  }

  /// Get pawns by color
  List<Pawn> getPawnsByColor(String color) {
    return pawns.where((pawn) => pawn.color == color).toList();
  }

  /// Get my player's pawns
  List<Pawn> getMyPawns() {
    if (myPlayerColor == null) return [];
    return getPawnsByColor(myPlayerColor!);
  }

  /// Enhanced pawn movement validation
  bool canPawnMove(Pawn pawn, int diceNumber) {
    // If pawn is at base, can only move with 1 or 6
    if (pawn.position == pawn.basePos) {
      return diceNumber == 1 || diceNumber == 6;
    }

    // If pawn is on board, check if move is valid
    final maxPosition = _getMaxPositionForColor(pawn.color);
    return pawn.position + diceNumber <= maxPosition;
  }

  /// Get maximum position for a color (finish line)
  int _getMaxPositionForColor(String color) {
    switch (color.toLowerCase()) {
      case 'red': return 73;
      case 'blue': return 79;
      case 'green': return 85;
      case 'yellow': return 91;
      default: return 73;
    }
  }

  /// Get movable pawns for current player
  List<Pawn> getMovablePawns() {
    if (!isMyTurn || !hasDiceBeenRolled || currentDiceNumber == null) return [];

    final myPawns = getMyPawns();
    return myPawns.where((pawn) => canPawnMove(pawn, currentDiceNumber!)).toList();
  }

  // === SOCKET ACTIONS ===

  /// Create a new room
  Future<void> createRoom({
    required String roomName,
    String? password,
    bool isPrivate = false,
    double? entryFee,
    double? prizePool,
    required int playerCount,
    required String userId,
    int maxPlayers = 4,
  }) async {
    if (!isConnected || currentPlayerName == null) {
      throw Exception('Socket not connected or player name not set');
    }

    final roomData = {
      'name': roomName,
      'creatorName': currentPlayerName!,
      'private': isPrivate,
      'password': password ?? '',
      'userId': userId,
      'maxPlayers': maxPlayers,
      'playerCount': playerCount ?? 0,
      'entryFee': entryFee ?? 0.0,
      'prizePool': prizePool ?? 0.0,
    };

    print('🏠 Creating room: $roomData');
    socket.emit('room:create', roomData);
  }

  /// Join an existing room
  Future<void> joinRoom({
    required String roomId,
    String? password,
  }) async {
    if (!isConnected || currentPlayerName == null) {
      throw Exception('Socket not connected or player name not set');
    }

    final joinData = {
      'roomId': roomId,
      'playerName': currentPlayerName!,
      'password': password ?? '',
    };

    print('🚪 Joining room: $joinData');
    socket.emit('room:join', joinData);
  }

  /// Fetch available rooms
  Future<void> fetchAvailableRooms({
    int? maxPlayers,
    double? entryFee,
  }) async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    print('📋 Fetching available rooms');
    socket.emit('room:rooms');
  }

  /// Mark player as ready
  void markPlayerReady() {
    if (!isConnected) return;
    print('✅ Marking player as ready');
    socket.emit('player:ready');
  }

  /// Leave current room
  void leaveRoom() {
    if (!isConnected) return;
    print('👋 Leaving room');
    socket.emit('room:leave');
    _resetGameState();
  }

  /// Request current game data from server
  void requestGameData() {
    if (!isConnected) return;
    print('📊 Requesting game data...');
    socket.emit('room:data');
  }

  // === ENHANCED CALLBACK SETTERS ===

  void setErrorHandler(Function(String) handler) => onError = handler;
  void setRoomCreatedHandler(Function(Room) handler) => onRoomCreated = handler;
  void setRoomJoinedHandler(Function(Room) handler) => onRoomJoined = handler;
  void setRoomsReceivedHandler(Function(List<Room>) handler) => onRoomsReceived = handler;
  void setGameStateHandler(Function(Room) handler) => onGameStateUpdate = handler;
  void setGameStartedHandler(Function(Room) handler) => onGameStarted = handler;
  void setPlayerJoinedHandler(Function(String, String) handler) => onPlayerJoined = handler;
  void setRoomLeftHandler(Function() handler) => onRoomLeft = handler;
  void setDiceRolledHandler(Function(int) handler) => onDiceRolled = handler;
  void setDiceRollingStateHandler(Function(bool) handler) => onDiceRollingStateChanged = handler;
  void setPawnsUpdatedHandler(Function(List<Pawn>) handler) => onPawnsUpdated = handler;
  void setGameWinnerHandler(Function(String) handler) => onGameWinner = handler;
  void setTurnChangedHandler(Function(String) handler) => onTurnChanged = handler;
  void setPawnMovedHandler(Function(Pawn, int, int) handler) => onPawnMoved = handler;

  // === UTILITIES ===

  bool get socketConnected => isConnected && socket.connected;
  bool get canRollDice => isMyTurn && !hasDiceBeenRolled && !isDiceRolling && socketConnected;
  bool get canMovePawn => isMyTurn && hasDiceBeenRolled && currentDiceNumber != null && socketConnected;

  Future<void> ensureConnection() async {
    if (!socketConnected && currentUserId != null && currentPlayerName != null) {
      await Future.delayed(Duration(seconds: 1));
      if (!socketConnected) {
        throw Exception('Socket connection lost');
      }
    }
  }

  @override
  void dispose() {
    _diceRollTimeout?.cancel();
    _turnTimeout?.cancel();

    if (socket.connected) {
      socket.disconnect();
    }
    socket.clearListeners();
    isConnected = false;

    // Clear all callbacks
    onError = null;
    onRoomCreated = null;
    onRoomJoined = null;
    onRoomsReceived = null;
    onGameStateUpdate = null;
    onGameStarted = null;
    onPlayerJoined = null;
    onRoomLeft = null;
    onDiceRolled = null;
    onDiceRollingStateChanged = null;
    onPawnsUpdated = null;
    onGameWinner = null;
    onTurnChanged = null;
    onPawnMoved = null;

    super.dispose();
  }
}