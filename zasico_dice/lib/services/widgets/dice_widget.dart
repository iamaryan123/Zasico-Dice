import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/game_constant.dart';
import 'dart:math' as math;

class DiceWidget extends StatefulWidget {
  final int? diceNumber;
  final bool isMyTurn;
  final VoidCallback onPressed;
  final AnimationController animation;
  final String? currentPlayer;
  final int remainingTime;

  const DiceWidget({
    super.key,
    required this.diceNumber,
    required this.isMyTurn,
    required this.onPressed,
    required this.animation,
    this.currentPlayer,
    this.remainingTime = 30,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _timerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _timerController = AnimationController(
      duration: Duration(seconds: widget.remainingTime),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    if (widget.isMyTurn) {
      _pulseController.repeat(reverse: true);
      _timerController.forward();
    }
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isMyTurn != oldWidget.isMyTurn) {
      if (widget.isMyTurn) {
        _pulseController.repeat(reverse: true);
        _timerController.reset();
        _timerController.forward();
      } else {
        _pulseController.stop();
        _timerController.stop();
      }
    }
  }

  void _handleDicePress() {
    if (!widget.isMyTurn || widget.diceNumber != null) return;

    setState(() {
      _isRolling = true;
    });

    // Shake animation
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });

    widget.onPressed();

    // Stop rolling after animation
    Future.delayed(GameConstants.diceRollDuration, () {
      if (mounted) {
        setState(() {
          _isRolling = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer Bar
          if (widget.isMyTurn) _buildTimerBar(),

          if (widget.isMyTurn) const SizedBox(height: 8),

          // Current Player Indicator
          _buildPlayerIndicator(),

          const SizedBox(height: 12),

          // Dice Container
          _buildDiceContainer(),

          const SizedBox(height: 8),

          // Status Text
          _buildStatusText(),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return Container(
      width: GameConstants.diceContainerSize,
      height: GameConstants.timerBarHeight,
      decoration: BoxDecoration(
        color: GameConstants.surfaceColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: GameConstants.dividerColor,
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _timerAnimation,
        builder: (context, child) {
          final progress = _timerAnimation.value;
          Color timerColor;

          if (progress > 0.6) {
            timerColor = GameConstants.successColor;
          } else if (progress > 0.3) {
            timerColor = GameConstants.warningColor;
          } else {
            timerColor = GameConstants.errorColor;
          }

          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: GameConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: timerColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: timerColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerIndicator() {
    if (widget.currentPlayer == null) return const SizedBox.shrink();

    final playerColor = GameConstants.getPlayerColor(widget.currentPlayer!);

    return AnimatedBuilder(
      animation: widget.isMyTurn ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isMyTurn ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  playerColor,
                  playerColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isMyTurn ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: playerColor.withOpacity(0.4),
                  blurRadius: widget.isMyTurn ? 12 : 6,
                  spreadRadius: widget.isMyTurn ? 2 : 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: playerColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      widget.currentPlayer![0].toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: playerColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isMyTurn ? 'YOUR TURN' : '${widget.currentPlayer!.toUpperCase()}\'S TURN',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiceContainer() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = math.sin(_shakeAnimation.value * math.pi * 8) * 2;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: GestureDetector(
            onTap: _handleDicePress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: GameConstants.diceContainerSize,
              height: GameConstants.diceContainerSize,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: widget.isMyTurn
                      ? [
                    GameConstants.accentColor.withOpacity(0.8),
                    GameConstants.accentColor.withOpacity(0.6),
                  ]
                      : [
                    GameConstants.surfaceColor,
                    GameConstants.cardBackgroundColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isMyTurn
                      ? GameConstants.accentColor
                      : GameConstants.dividerColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isMyTurn
                        ? GameConstants.accentColor
                        : Colors.black)
                        .withOpacity(0.3),
                    blurRadius: widget.isMyTurn ? 15 : 8,
                    spreadRadius: widget.isMyTurn ? 2 : 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildDiceContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiceContent() {
    if (_isRolling) {
      return _buildRollingDice();
    }

    if (widget.diceNumber != null) {
      return _buildDiceNumber(widget.diceNumber!);
    }

    return _buildWaitingDice();
  }

  Widget _buildRollingDice() {
    return Center(
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.animation.value * 4 * math.pi,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26, width: 1),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceNumber(int number) {
    return Center(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _buildDiceDots(number),
        ),
      ),
    );
  }

  Widget _buildWaitingDice() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino,
            size: 32,
            color: widget.isMyTurn ? Colors.white : GameConstants.secondaryTextColor,
          ),
          const SizedBox(height: 4),
          Text(
            widget.isMyTurn ? 'TAP' : 'WAIT',
            style: GoogleFonts.orbitron(
              color: widget.isMyTurn ? Colors.white : GameConstants.secondaryTextColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceDots(int number) {
    const double dotSize = 6.0;
    const Color dotColor = Colors.black87;

    switch (number) {
      case 1:
        return const Center(
          child: CircleAvatar(
            radius: dotSize / 2,
            backgroundColor: dotColor,
          ),
        );
      case 2:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: dotSize / 2,
                  backgroundColor: dotColor,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: dotSize / 2,
                  backgroundColor: dotColor,
                ),
              ),
            ),
          ],
        );
      case 3:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(6.0),
                child: CircleAvatar(
                  radius: dotSize / 2,
                  backgroundColor: dotColor,
                ),
              ),
            ),
            Center(
              child: CircleAvatar(
                radius: dotSize / 2,
                backgroundColor: dotColor,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(6.0),
                child: CircleAvatar(
                  radius: dotSize / 2,
                  backgroundColor: dotColor,
                ),
              ),
            ),
          ],
        );
      case 4:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
          ],
        );
      case 5:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
            Center(
              child: CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
          ],
        );
      case 6:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
                CircleAvatar(radius: dotSize / 2, backgroundColor: dotColor),
              ],
            ),
          ],
        );
      default:
        return Text(
          number.toString(),
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: dotColor,
          ),
        );
    }
  }

  Widget _buildStatusText() {
    String statusText;
    Color statusColor;

    if (widget.isMyTurn) {
      if (widget.diceNumber != null) {
        statusText = 'Move a pawn!';
        statusColor = GameConstants.successColor;
      } else {
        statusText = 'Roll the dice!';
        statusColor = GameConstants.accentColor;
      }
    } else {
      statusText = 'Waiting...';
      statusColor = GameConstants.secondaryTextColor;
    }

    return Text(
      statusText,
      style: GoogleFonts.orbitron(
        color: statusColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
}