// Additional UI components for better game experience

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';

// Game Status Widget
class GameStatusWidget extends StatefulWidget {
  final String? currentPlayer;
  final bool isMyTurn;
  final int timeLeft;
  final int? lastDiceRoll;
  final bool isGamePaused;

  const GameStatusWidget({
    Key? key,
    this.currentPlayer,
    required this.isMyTurn,
    required this.timeLeft,
    this.lastDiceRoll,
    required this.isGamePaused,
  }) : super(key: key);

  @override
  _GameStatusWidgetState createState() => _GameStatusWidgetState();
}

class _GameStatusWidgetState extends State<GameStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isMyTurn) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GameStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMyTurn && !oldWidget.isMyTurn) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isMyTurn && oldWidget.isMyTurn) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isMyTurn
              ? [ZasicoColors.primaryRed.withOpacity(0.3), ZasicoColors.primaryRed.withOpacity(0.1)]
              : [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isMyTurn ? ZasicoColors.primaryRed : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isMyTurn ? _pulseAnimation.value : 1.0,
                child: Text(
                  widget.isMyTurn ? 'YOUR TURN' : 'WAITING...',
                  style: GoogleFonts.orbitron(
                    color: widget.isMyTurn ? ZasicoColors.primaryRed : Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                'TIME',
                '${widget.timeLeft}s',
                widget.timeLeft <= 10 ? Colors.red : ZasicoColors.primaryText,
              ),
              _buildInfoItem(
                'DICE',
                widget.lastDiceRoll?.toString() ?? '-',
                ZasicoColors.primaryText,
              ),
              _buildInfoItem(
                'STATUS',
                widget.isGamePaused ? 'PAUSED' : 'PLAYING',
                widget.isGamePaused ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: ZasicoColors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Enhanced Dice Widget
class AnimatedDiceWidget extends StatefulWidget {
  final int? diceValue;
  final bool canRoll;
  final VoidCallback onRoll;
  final bool isRolling;

  const AnimatedDiceWidget({
    Key? key,
    this.diceValue,
    required this.canRoll,
    required this.onRoll,
    required this.isRolling,
  }) : super(key: key);

  @override
  _AnimatedDiceWidgetState createState() => _AnimatedDiceWidgetState();
}

class _AnimatedDiceWidgetState extends State<AnimatedDiceWidget>
    with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _glowController;
  late Animation<double> _rollAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rollAnimation = Tween<double>(begin: 0.0, end: 4.0 * 3.14159).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.canRoll) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedDiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _rollController.forward(from: 0.0);
    }

    if (widget.canRoll && !oldWidget.canRoll) {
      _glowController.repeat(reverse: true);
    } else if (!widget.canRoll && oldWidget.canRoll) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canRoll ? widget.onRoll : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rollAnimation, _glowAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.canRoll
                  ? [
                BoxShadow(
                  color: ZasicoColors.primaryRed.withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
                  : null,
            ),
            child: Transform.rotate(
              angle: _rollAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.canRoll ? ZasicoColors.primaryRed : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                  gradient: widget.canRoll
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ZasicoColors.primaryRed,
                      ZasicoColors.primaryRed.withOpacity(0.7),
                    ],
                  )
                      : null,
                ),
                child: Center(
                  child: widget.isRolling
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                      : _buildDiceFace(widget.diceValue ?? 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceFace(int value) {
    return Text(
      value.toString(),
      style: GoogleFonts.orbitron(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}

// Player Info Panel
class PlayerInfoPanel extends StatelessWidget {
  final List<dynamic> players; // Your Player model
  final String? currentTurnPlayerId;
  final Map<String, int> pawnsInHome;

  const PlayerInfoPanel({
    Key? key,
    required this.players,
    this.currentTurnPlayerId,
    required this.pawnsInHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final isCurrentTurn = currentTurnPlayerId == player.userId;
          final pawnsHome = pawnsInHome[player.userId] ?? 0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentTurn
                  ? _getPlayerColor(player.color).withOpacity(0.3)
                  : ZasicoColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrentTurn
                    ? _getPlayerColor(player.color)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isCurrentTurn
                  ? [
                BoxShadow(
                  color: _getPlayerColor(player.color).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPlayerColor(player.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isCurrentTurn)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  player.name,
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Home: $pawnsHome/4',
                  style: GoogleFonts.orbitron(
                    color: ZasicoColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getPlayerColor(String color) {
    switch (color.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      default: return Colors.grey;
    }
  }
}

// Game Chat Widget (Optional)
class GameChatWidget extends StatefulWidget {
  final Function(String) onSendMessage;
  final List<Map<String, dynamic>> messages;

  const GameChatWidget({
    Key? key,
    required this.onSendMessage,
    required this.messages,
  }) : super(key: key);

  @override
  _GameChatWidgetState createState() => _GameChatWidgetState();
}

class _GameChatWidgetState extends State<GameChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(GameChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ZasicoColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Game Chat',
              style: GoogleFonts.orbitron(
                color: ZasicoColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${message['playerName']}: ${message['message']}',
                    style: GoogleFonts.orbitron(
                      color: ZasicoColors.primaryText,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.orbitron(color: ZasicoColors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.orbitron(color: ZasicoColors.secondaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: ZasicoColors.primaryRed),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: ZasicoColors.primaryRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}