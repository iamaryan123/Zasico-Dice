import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/room.dart';
import '../../utils/game_constant.dart';
import '../../utils/colors.dart';

class GameHeader extends StatelessWidget {
  final Room room;
  final String? currentTurnPlayer;
  final bool isMyTurn;
  final AnimationController turnIndicatorAnimation;

  const GameHeader({
    super.key,
    required this.room,
    required this.currentTurnPlayer,
    required this.isMyTurn,
    required this.turnIndicatorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GameConstants.headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameConstants.cardBackgroundColor,
            GameConstants.cardBackgroundColor.withOpacity(0.8),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room name and info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: GoogleFonts.orbitron(
                          color: GameConstants.primaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prize Pool: \$${room.prizePool.toStringAsFixed(0)}',
                        style: GoogleFonts.orbitron(
                          color: ZasicoColors.primaryRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Room status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: room.started
                        ? GameConstants.successColor
                        : GameConstants.warningColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room.started ? 'PLAYING' : 'WAITING',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Current turn indicator
            _buildTurnIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    if (currentTurnPlayer == null) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: GameConstants.cardBackgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Waiting for game to start...',
            style: GoogleFonts.orbitron(
              color: GameConstants.secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final turnColor = GameConstants.getPlayerColor(currentTurnPlayer!);

    return AnimatedBuilder(
      animation: turnIndicatorAnimation,
      builder: (context, child) {
        return Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                turnColor.withOpacity(0.8),
                turnColor.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(
                  isMyTurn ? 0.5 + (turnIndicatorAnimation.value * 0.5) : 0.3
              ),
              width: 2,
            ),
            boxShadow: isMyTurn ? [
              BoxShadow(
                color: turnColor.withOpacity(
                    0.3 + (turnIndicatorAnimation.value * 0.4)
                ),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Player color indicator
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: turnColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    currentTurnPlayer![0].toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Turn text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMyTurn ? 'YOUR TURN' : '${currentTurnPlayer!.toUpperCase()}\'S TURN',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isMyTurn)
                      Text(
                        'Roll the dice to play!',
                        style: GoogleFonts.orbitron(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),

              // Turn indicator icon
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMyTurn ? Icons.touch_app : Icons.hourglass_empty,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}