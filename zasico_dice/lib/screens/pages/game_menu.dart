import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zasico_dice/screens/pages/room_list_screen.dart';

import '../../models/room.dart';
import '../../providers/game_provider.dart';
import '../../services/socket_service.dart';
import '../../utils/colors.dart';
import '../Auth/profile.dart';
import 'lobby.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> with TickerProviderStateMixin {
  late String _currentUserId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _firestore = FirebaseFirestore.instance;
  bool _isCreatingGame = false;
  String? _username;
  String? _profileImageUrl;
  double _cashBalance = 50.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _setupAnimations();
    _loadUserData();
    _initializeSocket();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeSocket() async {
    try {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (_username != null) {
        await socketService.connect(_currentUserId, _username!,);
      }
    } catch (e) {
      print('Socket initialization error: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.data()?['username'] ?? 'Player';
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
          _cashBalance = userDoc.data()?['cashBalance']?.toDouble() ?? 50.0;
          _isLoading = false;
        });

        // Initialize socket after we have username
        await _initializeSocket();
      }
    }
  }

  void _showRoomList(int playerCount, int amount) async {
    final socketService = Provider.of<SocketService>(context, listen: false);

    try {
      setState(() => _isLoading = true);

      // Ensure socket is connected
      await socketService.ensureConnection();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomListScreen(
            userId: _currentUserId,
            playerCount: playerCount,
            entryFee: amount.toDouble(),
            socketService: socketService,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to room list: $e');
      Fluttertoast.showToast(msg: 'Error loading rooms: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _joinGame(int amount, int playerCount) async {
    // Check if user has sufficient balance
    if (_cashBalance < amount) {
      _showInsufficientFunds();
      return;
    }

    setState(() => _isCreatingGame = true);

    try {
      // 1. Check available rooms first
      final availableRoom = await _findAvailableRoom(playerCount, amount);

      if (availableRoom != null) {
        await _joinExistingRoom(availableRoom, amount);
      } else {
        await _createNewRoom(playerCount, amount);
      }
    } catch (e) {
      print('Error joining/creating game: $e');
      _handleJoinGameError('Failed to join game: ${e.toString()}', amount);
    } finally {
      if (mounted) setState(() => _isCreatingGame = false);
    }
  }

  Future<Room?> _findAvailableRoom(int playerCount, int amount) async {
    final socketService = Provider.of<SocketService>(context, listen: false);
    final completer = Completer<Room?>();

    try {
      // Ensure connection
      await socketService.ensureConnection();

      // Set up callback to receive rooms
      socketService.setRoomsReceivedHandler((List<Room> rooms) {
        try {
          final available = rooms.where((room) =>
          room.playerCount == playerCount &&
              room.entryFee == amount &&
              !room.started &&
              !room.full
          ).toList();

          completer.complete(available.isNotEmpty ? available.first : null);
        } catch (e) {
          completer.complete(null);
        }
      });

      // Fetch available rooms
      await socketService.fetchAvailableRooms(
        maxPlayers: playerCount,
        entryFee: amount.toDouble(),
      );

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      print('Error finding available room: $e');
      return null;
    }
  }

  Future<void> _deductFromWallet(int amount) async {
    await _firestore.collection('users').doc(_currentUserId).update({
      'cashBalance': FieldValue.increment(-amount)
    });

    // Add transaction record
    await _firestore.collection('transactions').add({
      'userId': _currentUserId,
      'amount': -amount,
      'type': 'game_entry',
      'timestamp': FieldValue.serverTimestamp()
    });

    // Update local balance
    setState(() {
      _cashBalance -= amount;
    });
  }

  Future<void> _joinExistingRoom(Room room, int amount) async {
    final socketService = Provider.of<SocketService>(context, listen: false);

    try {
      // Deduct balance first
      await _deductFromWallet(amount);

      // Set up success callback
      socketService.setRoomJoinedHandler((Room joinedRoom) {
        if (mounted) {
          _navigateToLobby(socketService, joinedRoom);
        }
      });

      // Set up error callback
      socketService.setErrorHandler((String error) {
        if (mounted) {
          _handleJoinGameError(error, amount);
        }
      });

      // Join the room
      await socketService.joinRoom(roomId: room.id);
    } catch (e) {
      print('Error joining existing room: $e');
      _handleJoinGameError('Failed to join room: ${e.toString()}', amount);
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

  Future<void> _createNewRoom(int playerCount, int amount) async {
    final socketService = Provider.of<SocketService>(context, listen: false);

    try {
      // Deduct balance first
      await _deductFromWallet(amount);

      // Calculate prize pool based on player count and entry fee
      double prizePool = _calculatePrizePool(playerCount, amount.toDouble());


      // Set up success callback
      socketService.setRoomCreatedHandler((Room createdRoom) {
        if (mounted) {
          _navigateToLobby(socketService, createdRoom);
        }
      });

      // Set up error callback
      socketService.setErrorHandler((String error) {
        if (mounted) {
          _handleJoinGameError(error, amount);
        }
      });

      // Create the room
      await socketService.createRoom(
        userId: _currentUserId,
        roomName: '${playerCount}P \$$amount Game',
        isPrivate: false,
        maxPlayers: playerCount,
          entryFee: amount.toDouble(),
          prizePool:prizePool,
          playerCount: playerCount
      );
    } catch (e) {
      print('Error creating new room: $e');
      _handleJoinGameError('Failed to create room: ${e.toString()}', amount);
    }
  }

  void _navigateToLobby(SocketService socketService, Room room) {
    // Clear the callback handlers to prevent conflicts
    socketService.setRoomCreatedHandler((room) => Room,);
    socketService.setRoomJoinedHandler((room) => Room,);
    socketService.setErrorHandler((message) => '',);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(
          roomId: room.id,
          socketService: socketService,
          playerCount: room.playerCount,
          tierAmount: room.entryFee,
        ),
      ),
    );
  }

  void _handleJoinGameError(String message, int amount) async {
    // Refund the deducted amount if there was an error
    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'cashBalance': FieldValue.increment(amount)
      });

      setState(() {
        _cashBalance += amount;
      });
    } catch (e) {
      print('Error refunding amount: $e');
    }

    // Show error message to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A0A0A),
              Color(0xFF2D1B1B),
            ],
          ),
        ),
        child: Stack(
          children: [

            // Decorative elements
            Positioned(
              top: screenHeight * 0.1,
              right: 20,
              child: _buildFloatingShape(),
            ),
            Positioned(
              bottom: screenHeight * 0.25,
              left: 30,
              child: _buildFloatingShape(),
            ),

            // Main content
            SafeArea(
              child: ListView(
                children: [
                  // Game title
                  _buildGameTitle(),

                  // Wallet section
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: _buildWalletDashboard(),
                      );
                    },
                  ),

                  // Game modes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGameModes(),
                  ),

                  // Bottom actions
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25, top: 15),
                    child: _buildBottomActions(),
                  ),
                ],
              ),
            ),

            if (_isLoading) _buildLoadingOverlay(),

            Positioned(
              top: 45,
              left: 10,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: Icon(
                  Icons.list_sharp,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: ZasicoColors.primaryBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ZasicoColors.primaryRed,
                  ZasicoColors.darkRed,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo as drawer icon
                Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: 10),
                Text(
                  'Zasico Dice',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // User profile section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ZasicoColors.primaryRed,
                          ZasicoColors.darkRed,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ZasicoColors.redShadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.transparent,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? Text(
                        _username != null ? _username![0].toUpperCase() : 'P',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: GoogleFonts.orbitron(
                        color: ZasicoColors.secondaryText,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _username ?? 'Player',
                      style: GoogleFonts.orbitron(
                        color: ZasicoColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Balance info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Balance: \$${_cashBalance.toStringAsFixed(2)}',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 16,
              ),
            ),
          ),

          const Divider(color: ZasicoColors.secondaryText),

          // Menu items
          ListTile(
            leading: Icon(Icons.account_circle, color: ZasicoColors.primaryRed),
            title: Text(
              'Profile',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _navigateToProfile();
            },
          ),

          ListTile(
            leading: Icon(Icons.notifications, color: ZasicoColors.primaryRed),
            title: Text(
              'Notifications',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Notifications');
            },
          ),

          ListTile(
            leading: Icon(Icons.settings, color: ZasicoColors.primaryRed),
            title: Text(
              'Settings',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Settings');
            },
          ),

          ListTile(
            leading: Icon(Icons.help_outline, color: ZasicoColors.primaryRed),
            title: Text(
              'How to Play',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Game Guide');
            },
          ),

          ListTile(
            leading: Icon(Icons.leaderboard, color: ZasicoColors.primaryRed),
            title: Text(
              'Leaderboard',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Leaderboard');
            },
          ),

          ListTile(
            leading: Icon(Icons.history, color: ZasicoColors.primaryRed),
            title: Text(
              'Game History',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Game History');
            },
          ),

          const Divider(color: ZasicoColors.secondaryText),

          ListTile(
            leading: Icon(Icons.logout, color: ZasicoColors.primaryRed),
            title: Text(
              'Logout',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShape() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: ZasicoColors.primaryRed.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildWalletDashboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A).withOpacity(0.95),
            Color(0xFF2D1B1B).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZasicoColors.primaryRed.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: ZasicoColors.primaryRed.withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Balance Display
          Text(
            '\$${_cashBalance.toStringAsFixed(0)}',
            style: GoogleFonts.orbitron(
              color: ZasicoColors.primaryText,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: ZasicoColors.primaryRed.withOpacity(0.6),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CASH BALANCE',
            style: GoogleFonts.orbitron(
              color: ZasicoColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWalletActionButton(
                'Deposit',
                Icons.add,
                _showDepositOptions,
                isPrimary: true,
              ),
              const SizedBox(width: 20),
              _buildWalletActionButton(
                'Withdraw',
                Icons.payment,
                    () => _showComingSoon('Withdrawals'),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletActionButton(String title, IconData icon, VoidCallback onTap, {bool isPrimary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
            colors: [
              ZasicoColors.primaryRed,
              ZasicoColors.darkRed,
            ],
          )
              : LinearGradient(
            colors: [
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isPrimary ? ZasicoColors.redShadow : Colors.black,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: ZasicoColors.primaryText, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTitle() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Game Logo
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ZasicoColors.primaryRed.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: 90,
            height: 90,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Zasico Dice',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'PLAY & EARN REAL MONEY',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.primaryRed,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildGameModes() {
    return Column(
      children: [
        Text(
          'SELECT GAME MODE',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeCard(
              title: '2 PLAYER',
              subtitle: 'Head-to-head',
              icon: Icons.people,
              onTap: () => _showInvestmentTiers(2),
            ),
            _buildModeCard(
              title: '4 PLAYER',
              subtitle: 'Tournament',
              icon: Icons.groups,
              onTap: () => _showInvestmentTiers(4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ZasicoColors.primaryRed,
              ZasicoColors.darkRed,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ZasicoColors.redShadow,
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ZasicoColors.primaryText, size: 36),
            const SizedBox(height: 15),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: GoogleFonts.orbitron(
                color: ZasicoColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          'How to Play',
          Icons.help_outline,
              () => _showComingSoon('Game Guide'),
        ),
        const SizedBox(width: 25),
        _buildActionButton(
            'Leaderboard',
            Icons.leaderboard,
                () => _showComingSoon('Leaderboard')),
        const SizedBox(width: 25),
        _buildActionButton(
          'History',
          Icons.history,
              () => _showComingSoon('Game History'),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ZasicoColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: ZasicoColors.redOpacity30),
            ),
            child: Icon(icon, color: ZasicoColors.primaryText, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: ZasicoColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ZasicoColors.primaryRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading Game Data...',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvestmentTiers(int playerCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ZasicoColors.primaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: ZasicoColors.redShadow,
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: ZasicoColors.primaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '$playerCount PLAYER GAME',
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ZasicoColors.primaryText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your investment tier',
                    style: GoogleFonts.orbitron(
                      color: ZasicoColors.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildTierOptions(playerCount),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.orbitron(
                        color: ZasicoColors.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to show game availability
  Widget _buildGameAvailabilityIndicator(bool isAvailable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isAvailable ? Icons.group_add : Icons.group,
          size: 16,
          color: isAvailable ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          isAvailable ? 'Join existing' : 'Create new',
          style: GoogleFonts.orbitron(
            color: isAvailable ? Colors.green : ZasicoColors.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTierOptions(int playerCount) {
    final tiers = [
      {'amount': 25, 'fee': 2, 'prize': playerCount == 2 ? 45 : 90},
      {'amount': 50, 'fee': 4, 'prize': playerCount == 2 ? 90 : 180},
      {'amount': 100, 'fee': 8, 'prize': playerCount == 2 ? 180 : 360},
      {'amount': 500, 'fee': 40, 'prize': playerCount == 2 ? 900 : 1800},
    ];

    return tiers.map((tier) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // _joinGame(tier['amount'] as int, playerCount);
            _showRoomList(playerCount, tier['amount'] as int);
            },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: ZasicoColors.redGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ZasicoColors.redShadow,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    '\$${tier['amount']} ENTRY',
                    style: GoogleFonts.orbitron(
                      color: ZasicoColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PRIZE: \$${tier['prize']} | FEE: \$${tier['fee']}',
                    style: GoogleFonts.orbitron(
                      color: ZasicoColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // // Add this helper method
  // Future<bool> _isGameAvailable(int playerCount, int amount) async {
  //   try {
  //     final gameId = await _findAvailableGame(playerCount, amount.toDouble());
  //     return gameId != null;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  void _navigateToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
  }

  void _showInsufficientFunds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ZasicoColors.primaryBackground,
        title: Text(
          'INSUFFICIENT FUNDS',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You don\'t have enough cash to join this game.',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDepositOptions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ).copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: ZasicoColors.redGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ZasicoColors.redShadow,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  'ADD FUNDS',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ZasicoColors.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: ZasicoColors.primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ADD FUNDS',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ZasicoColors.primaryText,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPaymentOption('Credit/Debit Card', Icons.credit_card),
              _buildPaymentOption('Google Pay', Icons.payment),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: ZasicoColors.primaryRed),
      title: Text(
        title,
        style: GoogleFonts.orbitron(
          color: ZasicoColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward, color: ZasicoColors.secondaryText),
      onTap: () {
        Navigator.pop(context);
        _showAmountSelection(title);
      },
    );
  }

  void _showAmountSelection(String method) {
    final amounts = [25.0, 50.0, 100.0, 500.0, 1000.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: ZasicoColors.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: ZasicoColors.primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SELECT AMOUNT',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ZasicoColors.primaryText,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2,
                ),
                itemCount: amounts.length,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    onPressed: () => _processPayment(amounts[index], method),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: ZasicoColors.redGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: ZasicoColors.redShadow,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          '\$${amounts[index].toStringAsFixed(0)}',
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ZasicoColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _processPayment(double amount, String method) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing \$${amount.toStringAsFixed(0)} payment via $method...'),
        backgroundColor: ZasicoColors.primaryRed,
      ),
    );

    setState(() {
      _cashBalance += amount;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).update({
        'cashBalance': _cashBalance,
      });
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ZasicoColors.primaryBackground,
        title: Text(
          '$feature COMING SOON!',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '$feature feature is under development and will be available soon.',
          style: GoogleFonts.orbitron(
            color: ZasicoColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}