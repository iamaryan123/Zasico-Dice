import 'package:zasico_dice/models/pawn.dart';

import 'main_player_model.dart';
import 'player.dart';

class Room {
  final String id;
  final String name;
  final bool private; // Changed from isPrivate
  final bool full;    // Changed from isFull
  final bool started;
  final DateTime createDate;
  final List<Player> players;
  final List<Pawn> pawns;
  final int? rolledNumber;
  final String? winner;
  final String? movingPlayerId; // Not in response
  final DateTime? nextMoveTime; // Not in response
  final double entryFee;
  final double prizePool;
  final int playerCount;
  final String playerId;
  final int v; // Added for __v version field

  Room({
    required this.id,
    required this.name,
    this.private = false,
    this.full = false,
    this.started = false,
    required this.createDate,
    required this.players,
    required this.pawns,
    this.rolledNumber,
    this.winner,
    this.movingPlayerId,
    required this.playerId,
    this.nextMoveTime,
    required this.entryFee,
    required this.prizePool,
    required this.playerCount,
    required this.v, // Added
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? '', // Handle _id field
      name: json['name'] ?? '',
      private: json['private'] ?? false, // Match JSON field name
      full: json['full'] ?? false,       // Match JSON field name
      started: json['started'] ?? false,
      createDate: DateTime.parse(json['createDate']),
      players: (json['players'] as List? ?? [])
          .map((p) => Player.fromJson( p))
          .toList(),
      pawns: (json['pawns'] as List? ?? [])
          .map((p) => Pawn.fromJson(p))
          .toList(),
      rolledNumber: json['rolledNumber'],
      winner: json['winner'] ?? '',
      // These fields are not in the response JSON:
      movingPlayerId: null,
      nextMoveTime: null,
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      prizePool: (json['prizePool'] ?? 0).toDouble(),
      playerCount: json['playerCount'] ?? 2,
      v: json['__v'] ?? 0, playerId: json['playerId'], // Handle version field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'private': private,
      'full': full,
      'started': started,
      'createDate': createDate.toIso8601String(),
      // 'players': players.map((player) => player.()).toList(),
      'pawns': pawns.map((pawn) => pawn.toJson()).toList(),
      'rolledNumber': rolledNumber,
      'winner': winner,
      'movingPlayerId': movingPlayerId,
      'nextMoveTime': nextMoveTime?.toIso8601String(),
      'entryFee': entryFee,
      'prizePool': prizePool,
      'playerCount': playerCount,
      'playerId': playerId,
      '__v': v,
    };
  }


  Player? getPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.userId == playerId);
    } catch (_) {
      return null;
    }
  }

  List<Pawn> getPlayerPawns(String color) {
    return pawns.where((pawn) => pawn.color == color).toList();
  }

  bool isPlayerMoving(String playerId) {
    return movingPlayerId == playerId;
  }

    // Add this method to resolve the error
  Player? getCurrentlyMovingPlayer() {
    if (movingPlayerId == null) return null;
    return getPlayer(movingPlayerId!);
  }
}