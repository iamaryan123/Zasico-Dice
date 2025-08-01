const { sendToPlayersRolledNumber, sendWinner } = require('../socket/emits');

const rollDice = () => {
    const rolledNumber = Math.ceil(Math.random() * 6);
    return rolledNumber;
};

// Update makeRandomMove function
const makeRandomMove = async roomId => {
  const { updateRoom, getRoom } = require('../services/roomService');
  const room = await getRoom(roomId);
  if (room.winner) return;

  if (room.rolledNumber === null) {
    room.rolledNumber = rollDice();
    sendToPlayersRolledNumber(room._id.toString(), room.rolledNumber);
  }

  // Pass rolledNumber to getPawnsThatCanMove
  const pawnsThatCanMove = room.getPawnsThatCanMove(room.rolledNumber);

  if (pawnsThatCanMove.length > 0) {
    const randomPawn = pawnsThatCanMove[Math.floor(Math.random() * pawnsThatCanMove.length)];
    room.movePawn(randomPawn);
  }

  room.changeMovingPlayer();

  const winner = room.getWinner();
  if (winner) {
    room.endGame(winner);
    sendWinner(room._id.toString(), winner);
  }

  await updateRoom(room);
};

// Add more validations to isMoveValid
const isMoveValid = (session, pawn, room) => {
  if (!session || !pawn || !room) return false;
  if (session.color !== pawn.color) return false;

  const movingPlayer = room.getCurrentlyMovingPlayer();
  if (!movingPlayer) return false;

  return session.playerId === movingPlayer._id.toString();
};

module.exports = { rollDice, makeRandomMove, isMoveValid };
