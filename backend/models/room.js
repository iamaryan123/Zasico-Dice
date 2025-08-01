const mongoose = require('mongoose');
const { COLORS, MOVE_TIME } = require('../utils/constants');
const { makeRandomMove } = require('../handlers/handlersFunctions');
const timeoutManager = require('./timeoutManager.js');
const PawnSchema = require('./pawn');
const PlayerSchema = require('./player');

const RoomSchema = new mongoose.Schema({
    name: String,
    private: { type: Boolean, default: false },
    password: String,
    entryFee: { type: Number, default: 0.0 },
    prizePool: { type: Number, default: 0.0 },
    playerCount:  { type: Number, default: 0.0 },
    createDate: { type: Date, default: Date.now },
    started: { type: Boolean, default: false },
    full: { type: Boolean, default: false },
    nextMoveTime: Number,
    rolledNumber: Number,
    players: [PlayerSchema],
    playerId: { type: String, default: '' },
    winner: { type: String, default: '' },
    pawns: {
        type: [PawnSchema],
        default: () => {
            const startPositions = [];
            for (let i = 0; i < 16; i++) {
                let pawn = {};
                pawn.basePos = i;
                pawn.position = i;
                if (i < 4) pawn.color = COLORS[0];
                else if (i < 8) pawn.color = COLORS[1];
                else if (i < 12) pawn.color = COLORS[2];
                else if (i < 16) pawn.color = COLORS[3];
                startPositions.push(pawn);
            }
            return startPositions;
        },
    },
});

RoomSchema.methods.beatPawns = function (position, attackingPawnColor) {
    const pawnsOnPosition = this.pawns.filter(pawn => pawn.position === position);
    pawnsOnPosition.forEach(pawn => {
        if (pawn.color !== attackingPawnColor) {
            const index = this.getPawnIndex(pawn._id);
            this.pawns[index].position = this.pawns[index].basePos;
        }
    });
};

//RoomSchema.methods.changeMovingPlayer = function () {
//    if (this.winner) return;
//    const playerIndex = this.players.findIndex(player => player.nowMoving === true);
//    this.players[playerIndex].nowMoving = false;
//    if (playerIndex + 1 === this.players.length) {
//        this.players[0].nowMoving = true;
//    } else {
//        this.players[playerIndex + 1].nowMoving = true;
//    }
//    this.nextMoveTime = Date.now() + MOVE_TIME;
//    this.rolledNumber = null;
//    timeoutManager.clear(this._id.toString());
//    timeoutManager.set(makeRandomMove, MOVE_TIME, this._id.toString());
//};

RoomSchema.methods.movePawn = function (pawn) {
    const newPositionOfMovedPawn = pawn.getPositionAfterMove(this.rolledNumber);
    this.changePositionOfPawn(pawn, newPositionOfMovedPawn);
    this.beatPawns(newPositionOfMovedPawn, pawn.color);
};
// Add null checks in critical methods
RoomSchema.methods.getPawnsThatCanMove = function(rolledNumber) {
  const movingPlayer = this.getCurrentlyMovingPlayer();
  if (!movingPlayer || !movingPlayer.color) return [];

  const playerPawns = this.getPlayerPawns(movingPlayer.color);
  return playerPawns.filter(pawn => pawn.canMove(rolledNumber));
};

//RoomSchema.methods.getCurrentlyMovingPlayer = function() {
//  return this.players.find(player => player.nowMoving === true) || null;
//};

RoomSchema.methods.changeMovingPlayer = function() {
  if (this.winner) return;

  const currentIndex = this.players.findIndex(p => p.nowMoving);
  if (currentIndex === -1) {
    if (this.players.length > 0) {
      this.players[0].nowMoving = true;
    }
    return;
  }

  this.players[currentIndex].nowMoving = false;
  const nextIndex = (currentIndex + 1) % this.players.length;
  this.players[nextIndex].nowMoving = true;
  this.nextMoveTime = Date.now() + MOVE_TIME;
  this.rolledNumber = null;
  timeoutManager.clear(this._id.toString());
  timeoutManager.set(makeRandomMove, MOVE_TIME, this._id.toString());
};

RoomSchema.methods.changePositionOfPawn = function (pawn, newPosition) {
    const pawnIndex = this.getPawnIndex(pawn._id);
    this.pawns[pawnIndex].position = newPosition;
};

RoomSchema.methods.canStartGame = function () {
    return this.players.filter(player => player.ready).length >= 2;
};

RoomSchema.methods.startGame = function () {
    this.started = true;
    this.nextMoveTime = Date.now() + MOVE_TIME;
    this.players.forEach(player => (player.ready = true));
    this.players[0].nowMoving = true;
    timeoutManager.set(makeRandomMove, MOVE_TIME, this._id.toString());
};

RoomSchema.methods.endGame = function (winner) {
    timeoutManager.clear(this._id.toString());
    this.rolledNumber = null;
    this.nextMoveTime = null;
    this.players.map(player => (player.nowMoving = false));
    this.winner = winner;
    this.save();
};

//RoomSchema.methods.getWinner = function () {
//    if (this.pawns.filter(pawn => pawn.color === 'red' && pawn.position === 73).length === 4) {
//        return 'red';
//    }
//    if (this.pawns.filter(pawn => pawn.color === 'blue' && pawn.position === 79).length === 4) {
//        return 'blue';
//    }
//    if (this.pawns.filter(pawn => pawn.color === 'green' && pawn.position === 85).length === 4) {
//        return 'green';
//    }
//    if (this.pawns.filter(pawn => pawn.color === 'yellow' && pawn.position === 91).length === 4) {
//        return 'yellow';
//    }
//    return null;
//};

RoomSchema.methods.getWinner = function() {
  const WIN_POSITIONS = {
    'red': 73,
    'blue': 79,
    'green': 85,
    'yellow': 85  // Corrected to match green
  };

  for (const [color, winPos] of Object.entries(WIN_POSITIONS)) {
    if (this.pawns.filter(pawn => pawn.color === color && pawn.position >= winPos).length === 4) {
      return color;
    }
  }
  return null;
};

RoomSchema.methods.isFull = function () {
    if (this.players.length === 4) {
        this.full = true;
    }
    return this.full;
};

RoomSchema.methods.getPlayer = function (playerId) {
    return this.players.find(player => player._id.toString() === playerId.toString());
};

// Update addPlayer method
RoomSchema.methods.addPlayer = function(name, id) {
  if (this.isFull()) return;

  const usedColors = this.players.map(p => p.color);
  const availableColors = ['red', 'blue', 'green', 'yellow'].filter(c => !usedColors.includes(c));

  if (availableColors.length === 0) return;

  this.players.push({
    sessionID: id,
    name: name,
    ready: false,
    color: availableColors[0],
  });
};
RoomSchema.methods.getPawnIndex = function (pawnId) {
    return this.pawns.findIndex(pawn => pawn._id.toString() === pawnId.toString());
};

RoomSchema.methods.getPawn = function (pawnId) {
    return this.pawns.find(pawn => pawn._id.toString() === pawnId.toString());
};

RoomSchema.methods.getPlayerPawns = function (color) {
    return this.pawns.filter(pawn => pawn.color === color);
};

RoomSchema.methods.getCurrentlyMovingPlayer = function () {
    return this.players.find(player => player.nowMoving === true);
};

const Room = mongoose.model('Room', RoomSchema);

module.exports = Room;
