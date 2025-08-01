class Player {
  final String id;
  final String userId; // Added this field
  final String sessionId;
  final String name;
  final String color;
  late final bool ready;
  final bool nowMoving;
  final String playerId;

  Player({
    required this.id,
    required this.playerId,
    required this.userId, // Added
    required this.sessionId,
    required this.name,
    required this.color,
    this.ready = false,
    this.nowMoving = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '', // Added
      sessionId: json['sessionID'] ?? '', // Note uppercase D
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      ready: json['ready'] ?? false,
      nowMoving: json['nowMoving'] ?? false, playerId: json['_id'],
    );
  }
}