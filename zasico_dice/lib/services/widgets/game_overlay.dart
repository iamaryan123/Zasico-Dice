import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/game_constant.dart';
import 'dart:math' as math;

class GameOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.forward();
      _pulseController.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.8 * _fadeAnimation.value),
            child: Stack(
              children: [
                // Confetti background
                AnimatedBuilder(
                  animation: _confettiAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ConfettiPainter(
                        animation: _confettiAnimation,
                        primaryColor: widget.primaryColor,
                      ),
                      size: MediaQuery.of(context).size,
                    );
                  },
                ),

                // Main content
                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: GameConstants.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: widget.primaryColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Trophy icon
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: widget.primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.primaryColor.withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Title
                              Text(
                                widget.title,
                                style: GoogleFonts.orbitron(
                                  color: GameConstants.primaryTextColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                widget.subtitle,
                                style: GoogleFonts.orbitron(
                                  color: widget.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 32),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: GameConstants.cardBackgroundColor,
                                        foregroundColor: GameConstants.primaryTextColor,
                                        side: BorderSide(
                                          color: GameConstants.secondaryTextColor,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: widget.onExit,
                                      icon: const Icon(Icons.home),
                                      label: Text(
                                        'HOME',
                                        style: GoogleFonts.orbitron(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: widget.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: widget.onPlayAgain,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(
                                        'PLAY AGAIN',
                                        style: GoogleFonts.orbitron(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;

  ConfettiPainter({
    required this.animation,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < 50; i++) {
      final progress = animation.value;
      final x = random.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height + 20.0;
      final y = startY + (endY - startY) * progress;

      // Vary the colors
      final colors = [
        primaryColor,
        GameConstants.successColor,
        GameConstants.warningColor,
        Colors.purple,
        Colors.pink,
      ];

      paint.color = colors[i % colors.length].withOpacity(0.8);

      // Different shapes
      if (i % 3 == 0) {
        // Rectangle confetti
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 8,
            height: 4,
          ),
          paint,
        );
      } else if (i % 3 == 1) {
        // Circle confetti
        canvas.drawCircle(Offset(x, y), 4, paint);
      } else {
        // Triangle confetti
        final path = Path();
        path.moveTo(x, y - 4);
        path.lineTo(x - 4, y + 4);
        path.lineTo(x + 4, y + 4);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ConfettiPainter &&
        oldDelegate.animation.value != animation.value;
  }
}