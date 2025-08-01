class Pawn {
  final String id;
  final String color;
  final int position;
  final int basePos;
  final bool canMove;

  Pawn({
    required this.id,
    required this.color,
    required this.position,
    required this.basePos,
    this.canMove = false,
  });

  factory Pawn.fromJson(Map<String, dynamic> json) {
    return Pawn(
      id: json['_id'] ?? '',
      color: json['color'] ?? '',
      position: json['position'] ?? 0,
      basePos: json['basePos'] ?? 0,
      canMove: json['canMove'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'color': color,
      'position': position,
      'basePos': basePos,
      'canMove': canMove,
    };
  }

  /// Check if pawn is at its base position
  bool get isAtBase => position == basePos;

  /// Check if pawn is in finish area
  bool get isInFinishArea {
    switch (color.toLowerCase()) {
      case 'red':
        return position >= 68 && position <= 73;
      case 'blue':
        return position >= 74 && position <= 79;
      case 'green':
        return position >= 80 && position <= 85;
      case 'yellow':
        return position >= 86 && position <= 91;
      default:
        return false;
    }
  }

  /// Check if pawn is on the main board (not at base or finish)
  bool get isOnBoard => !isAtBase && !isInFinishArea;

  /// Get the finish line position for this pawn's color
  int get finishLinePosition {
    switch (color.toLowerCase()) {
      case 'red': return 73;
      case 'blue': return 79;
      case 'green': return 85;
      case 'yellow': return 91;
      default: return 73;
    }
  }

  /// Check if this pawn can move with the given dice number
  bool canMoveWithDice(int diceNumber) {
    // If at base, can only move with 1 or 6
    if (isAtBase) {
      return diceNumber == 1 || diceNumber == 6;
    }

    // If on board or in finish area, check if move doesn't exceed finish line
    return position + diceNumber <= finishLinePosition;
  }

  /// Get the new position after moving with dice number
  int getNewPositionAfterMove(int diceNumber) {
    if (isAtBase && (diceNumber == 1 || diceNumber == 6)) {
      // Move from base to starting position
      return _getStartingPosition();
    }

    // Normal move
    final newPosition = position + diceNumber;
    return newPosition <= finishLinePosition ? newPosition : position;
  }

  /// Get the starting position for this pawn's color
  int _getStartingPosition() {
    switch (color.toLowerCase()) {
      case 'red': return 16;
      case 'blue': return 55;
      case 'green': return 42;
      case 'yellow': return 29;
      default: return 16;
    }
  }

  /// Create a copy of this pawn with updated position
  Pawn copyWith({
    String? id,
    String? color,
    int? position,
    int? basePos,
    bool? canMove,
  }) {
    return Pawn(
      id: id ?? this.id,
      color: color ?? this.color,
      position: position ?? this.position,
      basePos: basePos ?? this.basePos,
      canMove: canMove ?? this.canMove,
    );
  }

  @override
  String toString() {
    return 'Pawn(id: $id, color: $color, position: $position, basePos: $basePos, canMove: $canMove)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pawn &&
        other.id == id &&
        other.color == color &&
        other.position == position &&
        other.basePos == basePos;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    color.hashCode ^
    position.hashCode ^
    basePos.hashCode;
  }
}