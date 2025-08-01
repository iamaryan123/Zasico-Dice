import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/room.dart';
import '../../services/socket_service.dart';
import '../../utils/colors.dart';
import 'lobby.dart';

class RoomListScreen extends StatefulWidget {
  final int playerCount;
  final double entryFee;
  final SocketService socketService;
  final String userId;

   const RoomListScreen({
    super.key,
    required this.playerCount,
    required this.entryFee,
    required this.socketService, required this.userId,
  });

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  List<Room> _rooms = [];
  bool _isLoading = true;
  bool _isCreatingRoom = false;

  @override
  void initState() {
    super.initState();
    _setupSocketCallbacks();
    _loadRooms();
  }

  @override
  void dispose() {
    // Clear the callback handlers
    widget.socketService.setRoomsReceivedHandler((rooms) => <Room>[],);
    widget.socketService.setRoomCreatedHandler((room) => Room,);
    widget.socketService.setRoomJoinedHandler((room) => Room,);
    widget.socketService.setErrorHandler((message) => '',);
    super.dispose();
  }

  void _setupSocketCallbacks() {
    // Set up callback handlers for socket events
    widget.socketService.setRoomsReceivedHandler((List<Room> rooms) {
      if (mounted) {
        // Filter rooms based on player count and entry fee
        final filteredRooms = rooms.where((room) =>
        room.playerCount == widget.playerCount &&
            room.entryFee == widget.entryFee &&
            !room.started &&
            !room.full
        ).toList();

        setState(() {
          _rooms = filteredRooms;
          _isLoading = false;
        });
      }
    });

    widget.socketService.setRoomCreatedHandler((Room room) {
      if (mounted) {
        setState(() => _isCreatingRoom = false);

        // Navigate to lobby for the created room
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomId: room.id,
              socketService: widget.socketService,
              playerCount: widget.playerCount,
              tierAmount: widget.entryFee,
            ),
          ),
        );
      }
    });

    widget.socketService.setRoomJoinedHandler((Room room) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate to lobby for the joined room
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomId: room.id,
              socketService: widget.socketService,
              playerCount: widget.playerCount,
              tierAmount: widget.entryFee,
            ),
          ),
        );
      }
    });

    widget.socketService.setErrorHandler((String message) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCreatingRoom = false;
        });
        _showError(message);
      }
    });
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await widget.socketService.fetchAvailableRooms(
        maxPlayers: widget.playerCount,
        entryFee: widget.entryFee,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load rooms: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZasicoColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          '${widget.playerCount} Player \$${widget.entryFee.toInt()} Rooms',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ZasicoColors.primaryRed),
            onPressed: _loadRooms,
          )
        ],
      ),
      body: _buildRoomListBody(),
      floatingActionButton: _buildCreateRoomButton(),
    );
  }

  Widget _buildRoomListBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_rooms.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRoomList();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ZasicoColors.primaryRed,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading available rooms...',
            style: GoogleFonts.orbitron(
              color: ZasicoColors.secondaryText,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_rooms.png',
              width: 150,
              height: 150,
              color: ZasicoColors.primaryRed.withOpacity(0.5),
            ),
            const SizedBox(height: 30),
            Text(
              'No Rooms Available',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'There are no active rooms for this game mode.',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: ZasicoColors.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a new room and invite friends!',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: ZasicoColors.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    return RefreshIndicator(
      onRefresh: _loadRooms,
      backgroundColor: ZasicoColors.primaryBackground,
      color: ZasicoColors.primaryRed,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _rooms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildRoomCard(_rooms[index]),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final isFull = room.players.length >= room.playerCount;
    final statusColor = room.started
        ? Colors.orange
        : isFull
        ? Colors.red
        : Colors.green;

    return Card(
      color: ZasicoColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: ZasicoColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _joinRoom(room),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: GoogleFonts.orbitron(
                        color: ZasicoColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      room.started
                          ? 'IN PROGRESS'
                          : isFull
                          ? 'FULL'
                          : 'OPEN',
                      style: GoogleFonts.orbitron(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(
                      Icons.people,
                      '${room.players.length}/${room.playerCount} Players'
                  ),
                  const SizedBox(width: 20),
                  _buildInfoItem(
                      Icons.emoji_events,
                      '\$${room.prizePool.toStringAsFixed(0)} Prize'
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Created ${_formatTimeDifference(room.createDate)}',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: ZasicoColors.primaryRed),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.orbitron(
            color: ZasicoColors.primaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateRoomButton() {
    return FloatingActionButton.extended(
      onPressed: _isCreatingRoom ? null : _createNewRoom,
      backgroundColor: ZasicoColors.primaryRed,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      icon: _isCreatingRoom
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Icon(Icons.add),
      label: Text(
        'CREATE ROOM',
        style: GoogleFonts.orbitron(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatTimeDifference(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Future<void> _joinRoom(Room room) async {
    if (room.started) {
      _showError('Game has already started');
      return;
    }

    if (room.players.length >= room.playerCount) {
      _showError('Room is full');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Deduct balance first
      await _deductFromWallet();

      // Join room using new socket service method
      await widget.socketService.joinRoom(
        roomId: room.id,
        password: room.private ? null : null, // Add password handling if needed
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to join room: ${e.toString()}');
      }
    }
  }

  // Add this helper method to calculate prize pool
  double _calculatePrizePool(int playerCount, double entryFee) {
    // Define the tiers based on your structure
    final tiers = [
      {'amount': 25, 'fee': 2, 'prize': playerCount == 2 ? 45 : 90},
      {'amount': 50, 'fee': 4, 'prize': playerCount == 2 ? 90 : 180},
      {'amount': 100, 'fee': 8, 'prize': playerCount == 2 ? 180 : 360},
      {'amount': 500, 'fee': 40, 'prize': playerCount == 2 ? 900 : 1800},
    ];

    // Find the matching tier based on entry fee
    for (var tier in tiers) {
      if (tier['amount'] == entryFee.toInt()) {
        return (tier['prize'] as int).toDouble();
      }
    }

    // Fallback calculation if no tier matches
    // Assuming prize pool is (entry fee * player count) minus platform fee
    return (entryFee * playerCount * 0.9); // 10% platform fee
  }

  Future<void> _createNewRoom() async {
    setState(() => _isCreatingRoom = true);
    try {
      // Deduct balance first
      await _deductFromWallet();

      // Calculate prize pool based on player count and entry fee
      double prizePool = _calculatePrizePool(widget.playerCount, widget.entryFee);


      // Create room using new socket service method
      await widget.socketService.createRoom(
        roomName: '${widget.playerCount}P \$${widget.entryFee.toInt()} Room',
        isPrivate: false,
        userId: widget.userId,
        maxPlayers: widget.playerCount,
        entryFee: widget.entryFee.toDouble(),
        prizePool:prizePool,
        playerCount: widget.playerCount
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
        _showError('Failed to create room: ${e.toString()}');
      }
    }
  }

  Future<void> _deductFromWallet() async {
    // In a real app, this would deduct from the user's wallet
    // For demo purposes, we'll just simulate a delay
    await Future.delayed(const Duration(milliseconds: 300));
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