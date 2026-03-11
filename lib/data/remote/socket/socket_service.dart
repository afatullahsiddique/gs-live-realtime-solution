import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;
  final _participantJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _newCommentController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get participantJoinedStream => _participantJoinedController.stream;
  Stream<Map<String, dynamic>> get newCommentStream => _newCommentController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  void connect(String token, String roomId) {
    if (_socket?.connected ?? false) return;

    _socket = io.io('https://gs-live-backend.onrender.com/ws/rooms/audio', 
      io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .build()
    );

    _socket!.onConnect((_) {
      debugPrint('🔌 [SOCKET] Connected');
      _connectionStatusController.add(true);
      _authenticate(token, roomId);
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 [SOCKET] Disconnected');
      _connectionStatusController.add(false);
    });

    _socket!.on('connection_established', (data) {
      debugPrint('🔌 [SOCKET] Connection established: $data');
    });

    _socket!.on('authenticated', (data) {
      debugPrint('🔌 [SOCKET] Authenticated: $data');
    });

    _socket!.on('authentication_failed', (data) {
      debugPrint('❌ [SOCKET] Authentication failed: $data');
    });

    _socket!.on('participant_joined', (data) {
      debugPrint('👥 [SOCKET] Participant joined: $data');
      _participantJoinedController.add(data);
    });

    _socket!.on('new_comment', (data) {
      debugPrint('💬 [SOCKET] New comment: $data');
      _newCommentController.add(data);
    });

    _socket!.on('error', (data) {
      debugPrint('❌ [SOCKET] Error: $data');
    });
  }

  void _authenticate(String token, String roomId) {
    debugPrint('🔌 [SOCKET] Authenticating for room: $roomId');
    _socket?.emit('authenticate', {
      'token': token,
      'roomId': roomId,
    });
  }

  void subscribeToChannels(List<String> channels) {
    _socket?.emit('subscribe', {'channels': channels});
  }

  void sendComment(String text, {String? parentId}) {
    final data = {
      'text': text,
    };
    if (parentId != null) {
      data['parentId'] = parentId;
    }
    debugPrint('🔌 [SOCKET] Sending comment: $data');
    _socket?.emit('send_comment', data);
  }

  void leaveRoom() {
    _socket?.emit('leave_room');
  }

  void disconnect() {
    leaveRoom();
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _participantJoinedController.close();
    _newCommentController.close();
    _connectionStatusController.close();
  }
}
