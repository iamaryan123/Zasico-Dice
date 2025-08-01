// import 'package:flutter/material.dart';
// import '../../models/game_state.dart';

// /// Widget representing a game token on the board
// class TokenWidget extends StatefulWidget {
//   final Player player;
//   final Token token;
//   final bool isCurrentPlayer;
//   final VoidCallback? onTap;
//   final bool isSelectable;
//   final bool isSelected;

//   const TokenWidget({
//     super.key,
//     required this.player,
//     required this.token,
//     this.isCurrentPlayer = false,
//     this.onTap,
//     this.isSelectable = false,
//     this.isSelected = false,
//   });

//   @override
//   State<TokenWidget> createState() => _TokenWidgetState();
// }

// class _TokenWidgetState extends State<TokenWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotationAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.2,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     ));

//     _rotationAnimation = Tween<double>(
//       begin: 0.0,
//       end: 0.1,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(TokenWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
    
//     // Animate when token is selected or becomes current player's turn
//     if (widget.isSelected && !oldWidget.isSelected) {
//       _animationController.forward();
//     } else if (!widget.isSelected && oldWidget.isSelected) {
//       _animationController.reverse();
//     }
//   }

//   Color get _tokenColor {
//     switch (widget.player.color.toString().toLowerCase()) {
//       case 'red':
//         return Colors.red;
//       case 'blue':
//         return Colors.blue;
//       case 'green':
//         return Colors.green;
//       case 'yellow':
//         return Colors.yellow;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animationController,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Transform.rotate(
//             angle: _rotationAnimation.value,
//             child: GestureDetector(
//               onTap: widget.isSelectable ? widget.onTap : null,
//               child: Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: _tokenColor,
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: widget.isSelected 
//                         ? Colors.white 
//                         : Colors.black.withOpacity(0.3),
//                     width: widget.isSelected ? 3 : 2,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                     if (widget.isCurrentPlayer)
//                       BoxShadow(
//                         color: _tokenColor.withOpacity(0.6),
//                         blurRadius: 8,
//                         spreadRadius: 2,
//                       ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Container(
//                     width: 12,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.8),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Center(
//                       child: Text(
//                         '${widget.token.id + 1}',
//                         style: TextStyle(
//                           fontSize: 8,
//                           fontWeight: FontWeight.bold,
//                           color: _tokenColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// /// Alternative simplified token widget for basic use cases
// class SimpleTokenWidget extends StatelessWidget {
//   final Color color;
//   final int tokenNumber;
//   final double size;
//   final bool isSelected;
//   final VoidCallback? onTap;

//   const SimpleTokenWidget({
//     super.key,
//     required this.color,
//     required this.tokenNumber,
//     this.size = 24.0,
//     this.isSelected = false,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: isSelected ? Colors.white : Colors.black.withOpacity(0.3),
//             width: isSelected ? 3 : 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.3),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Container(
//             width: size * 0.5,
//             height: size * 0.5,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.8),
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 '$tokenNumber',
//                 style: TextStyle(
//                   fontSize: size * 0.3,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }