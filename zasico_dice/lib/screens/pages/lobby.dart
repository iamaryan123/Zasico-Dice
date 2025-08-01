import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/main_player_model.dart';
import '../../models/player.dart';
import '../../models/room.dart';
import '../../providers/game_provider.dart';
import '../../services/socket_service.dart';
import '../../utils/colors.dart';
import 'Main_Game_Screen.dart';
import 'game.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final SocketService socketService;
  final int playerCount;
  final double tierAmount;

  const LobbyScreen({
    super.key,
    required this.roomId,
    required this.socketService,
    required this.playerCount,
    required this.tierAmount,
  });

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSocketCallbacks();

    // Add debug call
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugSocketConnection();
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  void _setupSocketCallbacks() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // Set up callback handlers for socket events
    widget.socketService.setGameStateHandler((Room room) {
      if (mounted) {
        print('Game state update received in lobby');
        gameProvider.updateRoom(room);
        setState(() {}); // Trigger UI update
      }
    });

    // FIXED: Enhanced game started handler with better logging
    widget.socketService.setGameStartedHandler((Room room) {
      print('=== GAME STARTED EVENT RECEIVED ===');
      print('Room: ${room.name}');
      print('Players: ${room.players.length}');
      print('Room started: ${room.started}');
      print('Current widget mounted: $mounted');

      if (mounted) {
        print('Processing game start...');
        gameProvider.startGame(room);

        // Add a small delay to ensure state is properly updated
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            print('Navigating to game...');
            _navigateToGame();
          }
        });
      } else {
        print('Widget not mounted, skipping navigation');
      }
    });

    widget.socketService.setPlayerJoinedHandler((String playerName, String color) {
      if (mounted) {
        print('Player $playerName joined as $color');
        // Optionally show a notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$playerName joined the room'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    widget.socketService.setErrorHandler((String message) {
      if (mounted) {
        print('Socket error: $message');
        _showError(message);
      }
    });

    widget.socketService.setRoomLeftHandler(() {
      if (mounted) {
        print('Room left event received');
        Navigator.pop(context);
      }
    });
  }


  void _navigateToGame() {
    print('=== NAVIGATE TO GAME CALLED ===');

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final room = gameProvider.currentRoom;

    if (room == null) {
      print('ERROR: Cannot navigate - room is null');
      _showError('Room data not available. Please try again.');
      return;
    }

    print('Room available: ${room.name}');
    print('Room started: ${room.started}');
    print('Players count: ${room.players.length}');

    // Initialize player if missing
    if (gameProvider.currentPlayer == null) {
      print('Initializing current player...');
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId != null) {
        // Find the current player in the room
        final currentRoomPlayer = room.players.firstWhere(
              (p) => p.userId == currentUserId,
          orElse: () {
            print('ERROR: Current user not found in room players');

            // 🔥 FIX: Create a fallback player with proper color handling
            final fallbackColorName = 'blue'; // Default color name
            final fallbackHexColor = '#0D92F4'; // Default hex color

            return Player(
              playerId: 'BP', // Default player ID for blue
              userId: currentUserId,
              name: widget.socketService.currentPlayerName ?? 'Unknown',
              color: fallbackHexColor, // 🔥 Use hex color, not color name
              id: '',
              ready: true,
              sessionId: widget.socketService.socket.id ?? '',
            );
          },
        );

        gameProvider.setPlayer(currentRoomPlayer);
        print('Player initialized: ${currentRoomPlayer.name} (${currentRoomPlayer.color})');
      }
    }

    print('Navigating to Game screen...');

    // Use pushReplacement to ensure clean navigation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameApp(
          socketService: widget.socketService,
        ),
        settings: RouteSettings(name: '/game'),
      ),
    ).then((_) {
      print('Navigation to game completed');
    }).catchError((error) {
      print('Navigation error: $error');
      _showError('Failed to navigate to game. Please try again.');
    });
  }

  void _debugSocketConnection() {
    print('=== SOCKET DEBUG INFO ===');
    print('Socket connected: ${widget.socketService.isConnected}');
    print('Socket ID: ${widget.socketService.socket.id}');
    print('Current user ID: ${widget.socketService.currentUserId}');
    print('Current player name: ${widget.socketService.currentPlayerName}');

    // Check if socket has listeners
    print('Socket has game:started listeners: ${widget.socketService.socket.hasListeners('game:started')}');
    print('Socket has room:data listeners: ${widget.socketService.socket.hasListeners('room:data')}');

    // Check callback handlers
    print('onGameStarted callback set: ${widget.socketService.onGameStarted != null}');
    print('onGameStateUpdate callback set: ${widget.socketService.onGameStateUpdate != null}');

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    print('Current room: ${gameProvider.currentRoom?.name}');
    print('Current player: ${gameProvider.currentPlayer?.name}');
    print('=== END SOCKET DEBUG ===');
  }


  void _showWinnerDialog(String winnerColor) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final room = gameProvider.currentRoom!;

    try {
      final winnerPlayer = room.players.firstWhere(
              (player) => player.color == winnerColor);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(winnerPlayer.userId)
          .update({'cashBalance': FieldValue.increment(room.prizePool)});

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: ZasicoColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 50,
                ),
                const SizedBox(height: 10),
                Text(
                  'VICTORY!',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${winnerColor.toUpperCase()} PLAYER',
                  style: GoogleFonts.orbitron(
                    color: _getPlayerColor(winnerColor),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'WINS THE MATCH!',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ZasicoColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Prize: \$${room.prizePool.toStringAsFixed(0)}',
                    style: GoogleFonts.orbitron(
                      color: ZasicoColors.primaryRed,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZasicoColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    'RETURN TO LOBBY',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing winner dialog: $e');
    }
  }

  Color _getPlayerColor(String color) {
    switch (color) {
      case 'red':
        return ZasicoColors.primaryRed;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    print('LobbyScreen disposing...');

    // Clear all callback handlers properly
    widget.socketService.onGameStateUpdate = null;
    widget.socketService.onGameStarted = null;
    widget.socketService.onPlayerJoined = null;
    widget.socketService.onError = null;
    widget.socketService.onRoomLeft = null;

    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final room = gameProvider.currentRoom;

    return Scaffold(
      backgroundColor: ZasicoColors.primaryBackground,
      body: SafeArea(
        child: room == null
            ? _buildLoadingScreen()
            : SlideTransition(
          position: _slideAnimation,
          child: _buildLobbyContent(gameProvider, room),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ZasicoColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: ZasicoColors.primaryRed,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Joining Room...',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyContent(GameProvider gameProvider, Room room) {
    return Column(
      children: [
        _buildRoomHeader(room),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPlayersList(room),
                const SizedBox(height: 20),
                if (gameProvider.error != null) _buildErrorMessage(gameProvider),
              ],
            ),
          ),
        ),
        _buildBottomSection(gameProvider, room),
      ],
    );
  }

  Widget _buildRoomHeader(Room room) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ZasicoColors.cardBackground,
            ZasicoColors.cardBackground.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ZasicoColors.primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ZasicoColors.primaryRed, width: 1),
                ),
                child: Text(
                  'ID: ${widget.roomId}',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Prize Pool',
                  '\$${room.prizePool.toStringAsFixed(0)}',
                  Icons.emoji_events,
                  ZasicoColors.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Entry Fee',
                  '\$${widget.tierAmount.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Players',
                  '${room.players.length}/${widget.playerCount}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: ZasicoColors.secondaryText,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(Room room) {
    return Container(
      decoration: BoxDecoration(
        color: ZasicoColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Players in Room',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: room.players.length,
            separatorBuilder: (context, index) => Divider(
              color: ZasicoColors.secondaryText.withOpacity(0.2),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final player = room.players[index];
              return _buildPlayerTile(player);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Player player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getPlayerColor(player.color.toString()),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getPlayerColor(player.color.toString()).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPlayerColor(player.color.toString()).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    player.color.toString().toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: _getPlayerColor(player.color.toString()),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: player.ready ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              player.ready ? Icons.check : Icons.hourglass_bottom,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(GameProvider gameProvider, Room room) {
    final currentPlayer = gameProvider.currentPlayer;
    final allPlayersReady = room.players.length >= widget.playerCount &&
        room.players.every((player) => player.ready);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ZasicoColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (allPlayersReady)
            _buildStartGameButton()
          else if (currentPlayer?.ready ?? false)
            _buildWaitingForOthers()
          else
            _buildReadyButton(),
        ],
      ),
    );
  }

  // In your LobbyScreen class, replace the _buildStartGameButton method with this:

  Widget _buildStartGameButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        onPressed: () async {
          try {
            print('Start game button pressed');

            // Add loading state
            setState(() {
              // You might want to add a loading flag here
            });

            // Emit the start game event
            print('Emitting game:start event with roomId: ${widget.roomId}');
            widget.socketService.socket.emit('game:start', {
              'roomId': widget.roomId,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

            // Add timeout for game start
            Timer(Duration(seconds: 10), () {
              if (mounted) {
                final gameProvider = Provider.of<GameProvider>(context, listen: false);
                if (gameProvider.currentRoom != null && !gameProvider.currentRoom!.started) {
                  print('Game start timeout - forcing navigation');
                  _showError('Game start took too long. Trying again...');

                  // Try alternative approach
                  _forceGameStart();
                }
              }
            });

          } catch (e) {
            print('Error starting game: $e');
            if (mounted) {
              _showError('Failed to start game. Please try again.');
            }
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'START GAME',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add this method to handle forced game start
  void _forceGameStart() {
    print('Attempting force game start...');
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (gameProvider.currentRoom != null) {
      // Update room state locally
      final room = gameProvider.currentRoom!;

      // Force navigation
      gameProvider.startGame(room);
      _navigateToGame();
    }
  }

  Widget _buildWaitingForOthers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Center(
        child: Text(
          'Waiting for other players to ready up...',
          style: GoogleFonts.orbitron(
            color: Colors.orange,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildReadyButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ZasicoColors.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              onPressed: () {
                widget.socketService.markPlayerReady();
              },
              child: Text(
                'READY UP',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(GameProvider gameProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              gameProvider.error!,
              style: GoogleFonts.orbitron(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.orbitron(),
        ),
        backgroundColor: Colors.red[900],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}