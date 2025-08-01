import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pawn.dart';
import '../../utils/game_constant.dart';
import 'dart:math' as math;

class GameBoard extends StatefulWidget {
  final List<Pawn> pawns;
  final List<Pawn> movablePawns;
  final Function(Pawn) onPawnPressed;
  final AnimationController pawnMoveAnimation;

  const GameBoard({
    super.key,
    required this.pawns,
    required this.movablePawns,
    required this.onPawnPressed,
    required this.pawnMoveAnimation,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  Pawn? _hintPawn;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: GameConstants.boardSize,
          height: GameConstants.boardSize,
          child: Stack(
            children: [
              // Board Background with Image
              _buildBoardBackground(),

              // Glow effects for movable positions
              ..._buildGlowEffects(),

              // Pawns with enhanced visuals
              ...widget.pawns.map((pawn) => _buildEnhancedPawn(pawn)),

              // Hint Pawn (for move preview)
              if (_hintPawn != null) _buildHintPawn(_hintPawn!),

              // Touch overlay for better interaction
              _buildTouchOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(GameConstants.boardImage),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGlowEffects() {
    return widget.movablePawns.map((pawn) {
      final position = GameConstants.getPositionCoordinates(pawn.position);
      final pawnColor = GameConstants.getPlayerColor(pawn.color);

      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Positioned(
            left: position.dx - 25,
            top: position.dy - 25,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pawnColor.withOpacity(_glowAnimation.value * 0.8),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildEnhancedPawn(Pawn pawn) {
    final position = GameConstants.getPositionCoordinates(pawn.position);
    final isMovable = widget.movablePawns.contains(pawn);
    final pawnColor = GameConstants.getPlayerColor(pawn.color);

    return AnimatedPositioned(
      duration: GameConstants.pawnMoveDuration,
      curve: GameConstants.pawnMoveAnimationCurve,
      left: position.dx - GameConstants.pawnRadius,
      top: position.dy - GameConstants.pawnRadius,
      child: GestureDetector(
        onTap: () => widget.onPawnPressed(pawn),
        child: AnimatedBuilder(
          animation: isMovable ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: isMovable ? _pulseAnimation.value : 1.0,
              child: _buildPawnWithImage(pawn, pawnColor, isMovable),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPawnWithImage(Pawn pawn, Color pawnColor, bool isMovable) {
    // If you have pawn images, use them
    return Container(
      width: GameConstants.pawnSize,
      height: GameConstants.pawnSize,
      child: Stack(
        children: [
          // Shadow/Glow base
          if (isMovable)
            Container(
              width: GameConstants.pawnSize + 6,
              height: GameConstants.pawnSize + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pawnColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),

          // Main pawn body
          Center(
            child: Container(
              width: GameConstants.pawnSize,
              height: GameConstants.pawnSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    pawnColor,
                    pawnColor.withOpacity(0.8),
                  ],
                ),
                border: Border.all(
                  color: isMovable ? Colors.white : Colors.black54,
                  width: isMovable ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: GameConstants.pawnSize * 0.5,
                  height: GameConstants.pawnSize * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: pawnColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      pawn.color[0].toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: pawnColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Highlight ring for movable pawns
          if (isMovable)
            Center(
              child: Container(
                width: GameConstants.pawnSize + 8,
                height: GameConstants.pawnSize + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintPawn(Pawn hintPawn) {
    final position = GameConstants.getPositionCoordinates(hintPawn.position);

    return Positioned(
      left: position.dx - GameConstants.pawnRadius,
      top: position.dy - GameConstants.pawnRadius,
      child: Container(
        width: GameConstants.pawnSize,
        height: GameConstants.pawnSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GameConstants.accentColor.withOpacity(0.3),
          border: Border.all(
            color: GameConstants.accentColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: GameConstants.accentColor.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.trending_flat,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTouchOverlay() {
    return Positioned.fill(
      child: Stack(
        children: widget.movablePawns.map((pawn) {
          final position = GameConstants.getPositionCoordinates(pawn.position);

          return Positioned(
            left: position.dx - GameConstants.touchRadius,
            top: position.dy - GameConstants.touchRadius,
            child: GestureDetector(
              onTap: () => widget.onPawnPressed(pawn),
              child: Container(
                width: GameConstants.touchRadius * 2,
                height: GameConstants.touchRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMoveHint(Pawn pawn, int diceNumber) {
    final newPosition = pawn.getNewPositionAfterMove(diceNumber);
    if (newPosition != pawn.position) {
      setState(() {
        _hintPawn = pawn.copyWith(position: newPosition);
      });

      // Hide hint after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _hintPawn = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}