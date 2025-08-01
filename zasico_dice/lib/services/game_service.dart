// import 'dart:convert';
//
//
// import '../models/player.dart';
// import '../models/room.dart';
// import '../providers/game_provider.dart';
// import 'socket_service.dart';
//
// class GameService {
//   static void handleSocketEvents(SocketService socket, GameProvider provider) {
//     socket.socket.on('player:data', (data) {
//       provider.setPlayerData(data);
//     });
//
//     // Add this to handle room creation responses
//     socket.socket.on('room:create:response', (response) {
//       if (response['success']) {
//         provider.createNewRoom(Room.fromJson(response['room']));
//       } else {
//         provider.setError(response['message']);
//       }
//     });
//
//     // Add pawn movement validation
//     socket.socket.on('game:move:response', (response) {
//       if (response['valid']) {
//         provider.updateRoom(Room.fromJson(response['room']));
//       } else {
//         provider.setError('Invalid move');
//       }
//     });
//
//     socket.socket.on('room:data', (data) {
//       provider.updateRoom(Room.fromJson(json.decode(data)));
//     });
//
//     socket.socket.on('room:rooms', (data) {
//       final rooms = (json.decode(data) as List)
//           .map((r) => Room.fromJson(r))
//           .toList();
//       provider.updateRoomList(rooms);
//     });
//
//     socket.socket.on('game:roll', (number) {
//       provider.setDiceRoll(number);
//     });
//
//     socket.socket.on('game:winner', (winner) {
//       provider.setWinner(winner);
//     });
//
//     socket.socket.on('error:wrongPassword', (_) {
//       provider.setError('Wrong password!');
//     });
//
//     socket.socket.on('error:changeRoom', (_) {
//       provider.setError('Room is full or game has started');
//     });
//
//     // Update these handlers:
//     socket.socket.on('room:created', (roomData) {
//       final room = Room.fromJson(json.decode(roomData));
//       provider.createNewRoom(room);
//     });
//
//     socket.socket.on('player:joined', (playerData) {
//       final player = Player.fromJson(json.decode(playerData));
//       provider.setPlayer(player);
//     });
//
//     socket.socket.on('game:started', (roomData) {
//       provider.updateRoom(Room.fromJson(json.decode(roomData)));
//       // You might want to trigger navigation here
//     });
//   }
// }