import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../utils/game_constant.dart';

class PlayerInfoPanel extends StatelessWidget {
  final List<Player> players;
  final String? currentTurnPlayer;
  final String? myPlayerColor;

  const PlayerInfoPanel({
    super.key,
    required this.players,
    required this.currentTurnPlayer,
    required this.myPlayerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GameConstants.playerInfoHeight,
      child: Row(
        children: [
          // Left side players (positions 0 and 1)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (players.length > 0) _buildPlayerCard(players[0], 0),
                if (players.length > 1) _buildPlayerCard(players[1], 1),
              ],
            ),
          ),

          // Center spacing
          const SizedBox(width: 20),

          // Right side players (positions 2 and 3)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (players.length > 2) _buildPlayerCard(players[2], 2),
                if (players.length > 3) _buildPlayerCard(players[3], 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Player player, int position) {
    final playerColor = GameConstants.getPlayerColor(player.color);
    final isCurrentTurn = currentTurnPlayer == player.color;
    final isMyPlayer = myPlayerColor == player.color;

    return Expanded(
      child: Container(
        height: GameConstants.playerInfoHeight,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              playerColor.withOpacity(isCurrentTurn ? 0.8 : 0.6),
              playerColor.withOpacity(isCurrentTurn ? 0.6 : 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMyPlayer
                ? Colors.white
                : isCurrentTurn
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.3),
            width: isMyPlayer ? 3 : isCurrentTurn ? 2 : 1,
          ),
          boxShadow: [
            if (isCurrentTurn)
              BoxShadow(
                color: playerColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Player avatar
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: playerColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                        style: GoogleFonts.orbitron(
                          color: playerColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Player name
                  Text(
                    player.name,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Status indicators
            Positioned(
              top: 4,
              right: 4,
              child: Column(
                children: [
                  // Current turn indicator
                  if (isCurrentTurn)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.green,
                          size: 8,
                        ),
                      ),
                    ),

                  const SizedBox(height: 2),

                  // My player indicator
                  if (isMyPlayer)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Ready status
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: player.ready ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.ready ? 'Ready' : 'Wait',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Position indicator
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${position + 1}',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}