import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';



void showToast(String title,Color color){
  Fluttertoast.showToast(
      msg: title,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0
  );
}

void requestFocus(FocusNode focusNode,BuildContext context) {
  FocusScope.of(context).requestFocus(focusNode);
}

Widget buildAnimatedBackground() {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 1.0, end: 1.2),
    duration: const Duration(seconds: 15),
    curve: Curves.easeInOut,
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    },
  );
}


// Future<void> moveForward({
//   required World world,
//   required Token token,
//   required List<String> tokenPath,
//   required int diceNumber,
// }) async {
//   // get all spots
//   final currentIndex = tokenPath.indexOf(token.positionId);
//   final finalIndex = currentIndex + diceNumber;
//
//   for (int i = currentIndex + 1; i <= finalIndex && i < tokenPath.length; i++) {
//     token.positionId = tokenPath[i];
//     await _applyEffect(
//       token,
//       MoveToEffect(
//         SpotManager()
//             .getSpots()
//             .firstWhere((spot) => spot.uniqueId == token.positionId)
//             .tokenPosition,
//         EffectController(duration: 0.12, curve: Curves.easeInOut),
//       ),
//     );
//
//     // Add a small delay to reduce CPU strain and smooth the animation
//     Future.delayed(const Duration(milliseconds: 120));
//   }
//
//   // if token is in home
//   bool isTokenInHome = await checkTokenInHomeAndHandle(token, world);
//
//   if (isTokenInHome) {
//     resizeTokensOnSpot(world);
//   } else {
//     tokenCollision(world, token);
//   }
//   clearTokenTrail();
//
// }
//
//
// void clearTokenTrail() {
//   final tokens = TokenManager().allTokens;
//   for (var token in tokens) {
//     token.disableCircleAnimation();
//   }
// }
//
// Future<void> _applyEffect(PositionComponent component, Effect effect) {
//   final completer = Completer<void>();
//   effect.onComplete = completer.complete;
//   component.add(effect);
//   return completer.future;
// }
//
// Future<void> moveTokenToBase({
//   required World world,
//   required Token token,
//   required Map<String, String> tokenBase,
//   required int homeSpotIndex,
//   required PositionComponent ludoBoard,
// }) async {
//   for (var entry in tokenBase.entries) {
//     var tokenId = entry.key;
//     var homePosition = entry.value;
//     if (token.tokenId == tokenId) {
//       token.positionId = homePosition;
//       token.state = TokenState.inBase;
//     }
//   }
//
//   await _applyEffect(
//     token,
//     MoveToEffect(
//       SpotManager().findSpotById(token.positionId).position,
//       EffectController(duration: 0.03, curve: Curves.easeInOut),
//     ),
//   );
//   Future.delayed(const Duration(milliseconds: 30));
// }
//
// Future<bool> checkTokenInHomeAndHandle(Token token, World world) async {
//   // Define home position IDs
//   const homePositions = ['BF', 'GF', 'YF', 'RF'];
//
//   // Check if the token is in home
//   if (!homePositions.contains(token.positionId)) return false;
//
//   token.state = TokenState.inHome;
//
//   // Cache players from GameState
//   // final players = GameState().players;
//   final player =
//       GameState().players.firstWhere((p) => p.playerId == token.playerId);
//   player.totalTokensInHome++;
//
//   // Handle win condition
//   if (player.totalTokensInHome == 4) {
//     player.hasWon = true;
//
//     // Get winners and non-winners
//     final playersWhoWon = GameState().players.where((p) => p.hasWon).toList();
//     final playersWhoNotWon =
//         GameState().players.where((p) => !p.hasWon).toList();
//
//     // End game condition
//     if (playersWhoWon.length == GameState().players.length - 1) {
//       playersWhoNotWon.first.rank =
//           GameState().players.length; // Rank last player
//       player.rank = playersWhoWon.length; // Set rank for current player
//       // Disable dice for all players
//       for (var p in GameState().players) {
//         p.enableDice = false;
//       }
//       for (var t in TokenManager().allTokens) {
//         t.enableToken = false;
//       }
//       EventBus().emit(OpenPlayerModalEvent());
//     } else {
//       // Set rank for current player
//       player.rank = playersWhoWon.length;
//     }
//     return true;
//   }
//
//   // Grant another turn if not all tokens are home
//
//   player.enableDice = true;
//   final lowerController = world.children.whereType<LowerController>().first;
//   lowerController.showPointer(player.playerId);
//   final upperController = world.children.whereType<UpperController>().first;
//   upperController.showPointer(player.playerId);
//
//   // Disable tokens for current player
//   for (var t in player.tokens) {
//     t.enableToken = false;
//   }
//
//   // Reset extra turns if applicable
//   if (player.hasRolledThreeConsecutiveSixes()) {
//     await player.resetExtraTurns();
//   }
//
//   player.grantAnotherTurn();
//   return true;
// }
//
//
// void moveOutOfBase({
//   required World world,
//   required Token token,
//   required List<String> tokenPath,
// }) async {
//   // Update token position to the first position in the path
//   token.positionId = tokenPath.first;
//   token.state = TokenState.onBoard;
//
//   await _applyEffect(
//       token,
//       MoveToEffect(SpotManager().findSpotById(tokenPath.first).tokenPosition,
//           EffectController(duration: 0.1, curve: Curves.easeInOut)));
//
//   tokenCollision(world, token);
// }
//
// void tokenCollision(World world, Token attackerToken) async {
//   final tokensOnSpot = TokenManager()
//       .allTokens
//       .where((token) => token.positionId == attackerToken.positionId)
//       .toList();
//
//   // Initialize the flag to track if any token was attacked
//   bool wasTokenAttacked = false;
//
//   // only attacker token on spot, return
//   if (tokensOnSpot.length > 1 &&
//       !['B04', 'B23', 'R22', 'R10', 'G02', 'G21', 'Y30', 'Y42']
//           .contains(attackerToken.positionId)) {
//     // Batch token movements
//     final tokensToMove = tokensOnSpot
//         .where((token) => token.playerId != attackerToken.playerId)
//         .toList();
//
//     if (tokensToMove.isNotEmpty) {
//       wasTokenAttacked = true;
//     }
//
//     // Wait for all movements to complete
//     await Future.wait(tokensToMove.map((token) => moveBackward(
//           world: world,
//           token: token,
//           tokenPath: GameState().getTokenPath(token.playerId),
//           ludoBoard: GameState().ludoBoard as PositionComponent,
//         )));
//   }
//
//   // Grant another turn or switch to next player
//   final player = GameState()
//       .players
//       .firstWhere((player) => player.playerId == attackerToken.playerId);
//
//   if (wasTokenAttacked) {
//     if (player.hasRolledThreeConsecutiveSixes()) {
//       player.resetExtraTurns();
//     }
//     player.grantAnotherTurn();
//   } else {
//     if (GameState().diceNumber != 6) {
//       GameState().switchToNextPlayer();
//     }
//   }
//
//   player.enableDice = true;
//
//   if (GameState().diceNumber == 6 || wasTokenAttacked == true) {
//     final lowerController = world.children.whereType<LowerController>().first;
//     final upperController = world.children.whereType<UpperController>().first;
//     lowerController.showPointer(player.playerId);
//     upperController.showPointer(player.playerId);
//   }
//
//   for (var token in player.tokens) {
//     token.enableToken = false;
//   }
//
//   // Call the function to resize tokens after moveBackward is complete
//   resizeTokensOnSpot(world);
// }
//
// void resizeTokensOnSpot(World world) {
//   final positionIncrements = {
//     1: 0,
//     2: 10,
//     3: 5,
//   };
//
//   // Group tokens by position ID
//   final Map<String, List<Token>> tokensByPositionId = {};
//   for (var token in TokenManager().allTokens) {
//     if (!tokensByPositionId.containsKey(token.positionId)) {
//       tokensByPositionId[token.positionId] = [];
//     }
//     tokensByPositionId[token.positionId]!.add(token);
//   }
//
//   tokensByPositionId.forEach((positionId, tokenList) {
//     // Precompute spot global position and adjusted position
//     final spot = SpotManager().findSpotById(positionId);
//
//     // Compute size factor and position increment
//     final positionIncrement = positionIncrements[tokenList.length] ?? 5;
//
//     // Resize and reposition tokens
//     for (var i = 0; i < tokenList.length; i++) {
//       final token = tokenList[i];
//       if (token.state == TokenState.inBase) {
//         token.position = spot.position;
//       } else if (token.state == TokenState.onBoard ||
//           token.state == TokenState.inHome) {
//         token.position = Vector2(
//             spot.tokenPosition.x + i * positionIncrement, spot.tokenPosition.y);
//       }
//     }
//   });
// }
//
// void addTokenTrail(List<Token> tokensInBase, List<Token> tokensOnBoard) {
//   var trailingTokens = [];
//
//   for (var token in tokensOnBoard) {
//     if (!token.spaceToMove()) {
//       continue;
//     }
//     trailingTokens.add(token);
//   }
//
//   if (GameState().diceNumber == 6) {
//     for (var token in tokensInBase) {
//       trailingTokens.add(token);
//     }
//   }
//
//   for (var token in trailingTokens) {
//     token.enableCircleAnimation();
//   }
// }
//
// Future<void> moveBackward({
//   required World world,
//   required Token token,
//   required List<String> tokenPath,
//   required PositionComponent ludoBoard,
// }) async {
//   final currentIndex = tokenPath.indexOf(token.positionId);
//   const finalIndex = 0;
//
//   // Preload audio to avoid delays during playback
//   bool audioPlayed = false;
//
//   for (int i = currentIndex; i >= finalIndex; i--) {
//     token.positionId = tokenPath[i];
//
//     if (!audioPlayed) {
//       FlameAudio.play('move.mp3');
//       audioPlayed = true;
//     }
//
//     await _applyEffect(
//       token,
//       MoveToEffect(
//         SpotManager()
//             .getSpots()
//             .firstWhere((spot) => spot.uniqueId == token.positionId)
//             .tokenPosition,
//         EffectController(duration: 0.1, curve: Curves.easeInOut),
//       ),
//     );
//   }
//
//   if (token.playerId == 'BP') {
//     await moveTokenToBase(
//       world: world,
//       token: token,
//       tokenBase: TokenManager().blueTokensBase,
//       homeSpotIndex: 6,
//       ludoBoard: ludoBoard,
//     );
//   } else if (token.playerId == 'GP') {
//     await moveTokenToBase(
//       world: world,
//       token: token,
//       tokenBase: TokenManager().greenTokensBase,
//       homeSpotIndex: 2,
//       ludoBoard: ludoBoard,
//     );
//   } else if (token.playerId == 'RP') {
//     await moveTokenToBase(
//       world: world,
//       token: token,
//       tokenBase: TokenManager().redTokensBase,
//       homeSpotIndex: 0,
//       ludoBoard: ludoBoard,
//     );
//   } else if (token.playerId == 'YP') {
//     await moveTokenToBase(
//       world: world,
//       token: token,
//       tokenBase: TokenManager().yellowTokensBase,
//       homeSpotIndex: 8,
//       ludoBoard: ludoBoard,
//     );
//   }
// }


