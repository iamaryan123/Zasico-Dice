const { getRoom, updateRoom } = require('../services/roomService');
const { COLORS } = require('../utils/constants');

module.exports = socket => {
    const req = socket.request;

    // FIXED: Login handler that works with your model
    const handleLogin = async (data) => {
        try {
            if (!data.roomId || !data.playerName) {
                socket.emit('room:error', { message: 'Room ID and player name required' });
                return;
            }

            const room = await getRoom(data.roomId);
            if (!room) {
                socket.emit('room:error', { message: 'Room not found' });
                return;
            }

            if (room.isFull()) {
                socket.emit('room:error', { message: 'Room is full' });
                return;
            }

            if (room.started) {
                socket.emit('room:error', { message: 'Game already started' });
                return;
            }

            if (room.private && room.password !== data.password) {
                socket.emit('room:error', { message: 'Wrong password' });
                return;
            }

            // Add player using model method
            room.addPlayer(data.playerName, socket.id);

            // Check if room should auto-start
            if (room.isFull()) {
                room.startGame();
            }

            await room.save();

            // Set up session
            const newPlayer = room.players[room.players.length - 1];
            req.session.roomId = room._id.toString();
            req.session.playerId = newPlayer._id.toString();
            req.session.color = newPlayer.color;
            req.session.save();

            // Join socket room
            socket.join(room._id.toString());

            socket.emit('player:data', JSON.stringify(req.session));

        } catch (error) {
            console.error('Error in handleLogin:', error);
            socket.emit('room:error', { message: 'Login failed' });
        }
    };

    const handleExit = async () => {
        req.session.reload(err => {
            if (err) return socket.disconnect();
            req.session.destroy();
            socket.emit('redirect');
        });
    };

    // Use existing ready handler from roomHandler instead
    const handleReady = async () => {
        try {
            const room = await getRoom(req.session.roomId);
            if (!room) return;

            const player = room.getPlayer(req.session.playerId);
            if (!player) return;

            player.changeReadyStatus();

            if (room.canStartGame()) {
                room.startGame();
            }

            await room.save();
        } catch (error) {
            console.error('Error in ready:', error);
        }
    };

    socket.on('player:login', handleLogin);
    socket.on('player:ready', handleReady);
    socket.on('player:exit', handleExit);
};