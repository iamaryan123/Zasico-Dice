const { getRooms, getRoom, updateRoom, createNewRoom } = require('../services/roomService');
const { sendToOnePlayerRooms, sendToOnePlayerData, sendWinner, sendToPlayersData } = require('../socket/emits');

module.exports = socket => {
    const req = socket.request;

    const handleGetData = async () => {
        try {
            if (!req.session.roomId) {
                socket.emit('room:error', { message: 'No room ID in session' });
                return;
            }

            const room = await getRoom(req.session.roomId);
            if (!room) {
                socket.emit('room:error', { message: 'Room not found' });
                return;
            }

            // Handle reconnection after time expiry
            if (room.nextMoveTime && room.nextMoveTime <= Date.now()) {
                room.changeMovingPlayer();
                await updateRoom(room);
            }

            sendToOnePlayerData(socket.id, room);
            if (room.winner) sendWinner(socket.id, room.winner);
        } catch (error) {
            console.error('Error in handleGetData:', error);
            socket.emit('room:error', { message: 'Failed to get room data' });
        }
    };

    const handleGetAllRooms = async () => {
        try {
            const rooms = await getRooms();
            // Filter only joinable rooms for Flutter
            const joinableRooms = rooms.filter(room => !room.started && !room.isFull());
            sendToOnePlayerRooms(socket.id, joinableRooms);
        } catch (error) {
            console.error('Error in handleGetAllRooms:', error);
            socket.emit('room:error', { message: 'Failed to get rooms' });
        }
    };

    // FIXED: Create room compatible with your Room model
    const handleCreateRoom = async (data) => {
        try {
            console.log('Creating room with data:', data);

            if (!data.name || !data.creatorName) {
                socket.emit('room:error', {
                    message: 'Room name and creator name are required'
                });
                return;
            }

            const roomData = {
                name: data.name,
                private: data.private || false,
                password: data.password || '',
                playerId:data.playerId || '',
                entryFee: data.entryFee || 0.0,
                    prizePool: data.prizePool || 0.0,
                    playerCount:  data.playerCount || 0.0,
                // Your Room model already handles pawns creation in default function
                // No need to specify players array - it's handled by schema
            };

            const newRoom = await createNewRoom(roomData);

            // Add creator as first player using existing model method
            newRoom.addPlayer(data.creatorName, socket.id);
            await newRoom.save();

            // Set up session for creator
            req.session.roomId = newRoom._id.toString();
            req.session.playerId = newRoom.players[0]._id.toString();
            req.session.playerName = data.creatorName;
            req.session.color = newRoom.players[0].color;
            req.session.save();

            // Join socket room
            socket.join(newRoom._id.toString());

            // Send success response
            socket.emit('room:created', {
                success: true,
                room: JSON.stringify(newRoom),
                playerId: req.session.playerId
            });

            // Refresh room list for all clients
            const rooms = await getRooms();
            const joinableRooms = rooms.filter(room => !room.started && !room.isFull());
            socket.broadcast.emit('room:rooms', JSON.stringify(joinableRooms));

            console.log(`Room created: ${newRoom._id} by ${data.creatorName}`);

        } catch (error) {
            console.error('Error creating room:', error);
            socket.emit('room:error', {
                message: 'Failed to create room: ' + error.message
            });
        }
    };

    // NEW: Handle joining existing room
    const handleJoinRoom = async (data) => {
        try {
            const { roomId, playerName, password } = data;

            if (!roomId || !playerName) {
                socket.emit('room:error', {
                    message: 'Room ID and player name are required'
                });
                return;
            }

            const room = await getRoom(roomId);
            if (!room) {
                socket.emit('room:error', { message: 'Room not found' });
                return;
            }

            // Use existing model methods for validation
            if (room.isFull()) {
                socket.emit('room:error', { message: 'Room is full' });
                return;
            }

            if (room.started) {
                socket.emit('room:error', { message: 'Game already started' });
                return;
            }

            if (room.private && room.password !== password) {
                socket.emit('room:error', { message: 'Wrong password' });
                return;
            }

            // Check if player already in room
            const existingPlayer = room.players.find(p => p.sessionID === socket.id);
            if (existingPlayer) {
                socket.emit('room:error', { message: 'Already in this room' });
                return;
            }

            // Add player using existing model method
            room.addPlayer(playerName, socket.id);
            await room.save();

            // Set up session
            const newPlayer = room.players[room.players.length - 1];
            req.session.roomId = roomId;
            req.session.playerId = newPlayer._id.toString();
            req.session.playerName = playerName;
            req.session.color = newPlayer.color;
            req.session.save();

            // Join socket room
            socket.join(roomId);

            // Send success response
            socket.emit('room:joined', {
                success: true,
                room: JSON.stringify(room),
                playerId: req.session.playerId,
                playerColor: newPlayer.color
            });

            // Notify all players in room about new player
            socket.to(roomId).emit('player:joined', {
                playerName: playerName,
                playerColor: newPlayer.color,
                totalPlayers: room.players.length
            });

            // Send updated room data to all players
            sendToPlayersData(room);

            console.log(`Player ${playerName} joined room ${roomId}`);

        } catch (error) {
            console.error('Error joining room:', error);
            socket.emit('room:error', {
                message: 'Failed to join room: ' + error.message
            });
        }
    };

    // FIXED: Use existing model ready system
    const handlePlayerReady = async () => {
        try {
            if (!req.session.roomId || !req.session.playerId) {
                socket.emit('room:error', { message: 'Not in any room' });
                return;
            }

            const room = await getRoom(req.session.roomId);
            if (!room) {
                socket.emit('room:error', { message: 'Room not found' });
                return;
            }

            const player = room.getPlayer(req.session.playerId);
            if (!player) {
                socket.emit('room:error', { message: 'Player not found in room' });
                return;
            }

            // Use existing model method
            player.changeReadyStatus();
            await room.save();

            // Send updated room data to all players
            sendToPlayersData(room);

            // Check if game can start using existing model method
            if (room.canStartGame() && !room.started) {
                // Use existing model start game method
                room.startGame();
                await room.save();

                // Notify all players game started
                socket.to(room._id.toString()).emit('game:started', {
                    message: 'Game Started!',
                    room: JSON.stringify(room)
                });
                socket.emit('game:started', {
                    message: 'Game Started!',
                    room: JSON.stringify(room)
                });

                console.log(`Game started in room ${room._id}`);
            }

            console.log(`Player ${player.name} ready status: ${player.ready}`);

        } catch (error) {
            console.error('Error in player ready:', error);
            socket.emit('room:error', {
                message: 'Failed to update ready status'
            });
        }
    };

    // NEW: Handle leaving room
   // Update handleLeaveRoom function
   const handleLeaveRoom = async () => {
     try {
       if (!req.session.roomId) return;

       const room = await getRoom(req.session.roomId);
       if (!room) return;

       // Remove player by session ID
       const playerIndex = room.players.findIndex(p => p.sessionID === socket.id);
       if (playerIndex === -1) return;

       room.players.splice(playerIndex, 1);
       room.full = false;

       // Handle current player index
       if (room.gameInProgress) {
         if (room.currentPlayerIndex === playerIndex) {
           room.changeMovingPlayer();
         } else if (room.currentPlayerIndex > playerIndex) {
           room.currentPlayerIndex--;
         }
       }

       if (room.players.length === 0) {
         await Room.findByIdAndDelete(room._id);
       } else {
         await room.save();
         sendToPlayersData(room);
       }

       socket.leave(req.session.roomId);
       req.session.destroy();
       socket.emit('room:left');
     } catch (error) {
       console.error('Error leaving room:', error);
     }
   };

    // Register socket events
    socket.on('room:data', handleGetData);
    socket.on('room:rooms', handleGetAllRooms);
    socket.on('room:create', handleCreateRoom);
    socket.on('room:join', handleJoinRoom);
    socket.on('player:ready', handlePlayerReady);
    socket.on('room:leave', handleLeaveRoom);

    // Handle disconnect
    socket.on('disconnect', handleLeaveRoom);
};