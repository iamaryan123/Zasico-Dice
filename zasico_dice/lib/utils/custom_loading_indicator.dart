import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final double dotSize;
  final double spacing;
  final Color dotColor;

  const CustomLoadingIndicator({
    super.key,
    this.dotSize = 8.0, // Reduced dot size
    this.spacing = 6.0,  // Reduced spacing
    this.dotColor = Colors.white,
  });

  @override
  _CustomLoadingIndicatorState createState() =>
      _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Create staggered opacity animations for each dot
    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2, // Delays the animation for each dot
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Center(
      child: Row( // Changed from Column to Row
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Opacity(
                opacity: _animations[index].value,
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 3 ? widget.spacing : 0, // Adjusted for horizontal spacing
                  ),
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
