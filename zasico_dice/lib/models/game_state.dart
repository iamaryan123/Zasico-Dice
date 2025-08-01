// // game_state.dart
// import 'dart:ui';

// class GameState {
//   final String roomId;
//   final int currentPlayer;
//   final int diceValue;
//   final List<Player> players;
//   final int gameStatus; // 0: waiting, 1: rolling, 2: moving

//   GameState({
//     required this.roomId,
//     required this.currentPlayer,
//     required this.diceValue,
//     required this.players,
//     required this.gameStatus,
//   });

//   factory GameState.fromJson(Map<String, dynamic> json) {
//     return GameState(
//       roomId: json['roomId'],
//       currentPlayer: json['currentPlayer'],
//       diceValue: json['diceValue'],
//       players: (json['players'] as List)
//           .map((player) => Player.fromJson(player))
//           .toList(),
//       gameStatus: json['gameStatus'],
//     );
//   }
// }

// // player.dart
// class Player {
//   final String id;
//   final String name;
//   final Color color;
//   final List<Token> tokens;
//   final bool isBot;

//   Player({
//     required this.id,
//     required this.name,
//     required this.color,
//     required this.tokens,
//     required this.isBot,
//   });

//   factory Player.fromJson(Map<String, dynamic> json) {
//     return Player(
//       id: json['id'],
//       name: json['name'],
//       color: Color(json['color']),
//       tokens: (json['tokens'] as List)
//           .map((token) => Token.fromJson(token))
//           .toList(),
//       isBot: json['isBot'],
//     );
//   }
// }

// // token.dart
// class Token {
//   final int id;
//   final int position;
//   final bool isHome;

//   Token({
//     required this.id,
//     required this.position,
//     required this.isHome,
//   });

//   factory Token.fromJson(Map<String, dynamic> json) {
//     return Token(
//       id: json['id'],
//       position: json['position'],
//       isHome: json['isHome'],
//     );
//   }
// }