import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final _usersCollection = _firestore.collection('users');
  static final DatabaseReference _roomsRef = _database.ref('rooms');
  static final DatabaseReference _connectedRef = _database.ref('.info/connected');

  // Keep track of presence references for cleanup
  static DatabaseReference? _currentParticipantRef;

  static Future<String> createRoom({String? password}) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.push();
    final roomId = roomRef.key!;

    final userRef = _usersCollection.doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw Exception("User profile not found. Cannot create room.");
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String hostName = userData['displayName'] ?? 'Anonymous';
    final String displayId = userData['displayId'] ?? '';
    final String? hostPicture = userData['photoUrl'];
    final String? preferredSkin = userData['preferredRoomSkin'];

    final bool isLocked = password != null && password.isNotEmpty;

    // Create room data
    await roomRef.set({
      'hostId': user.uid,
      'hostDisplayId': displayId,
      'hostName': hostName,
      'hostPicture': hostPicture,
      'createdAt': ServerValue.timestamp,
      'isActive': true,
      'participantCount': 1,
      'isMoveAllowed': true,
      'isSeatApprovalRequired': true,
      'isLocked': isLocked,
      'password': isLocked ? password : null,
      if (preferredSkin != null) 'backgroundUrl': preferredSkin,
    });

    // Add host as participant with presence detection
    final participantRef = roomRef.child('room_participants/${user.uid}');
    await participantRef.set({
      'userId': user.uid,
      'displayId': displayId,
      'userName': hostName,
      'userPicture': hostPicture,
      'isCoHost': true,
      'seatNo': 0,
      'joinedAt': ServerValue.timestamp,
      'isOnline': true,
      'isMuted': false,
    });

    // --- CHANGED: Pass isHost: true ---
    await _setupPresence(roomId, user.uid, isHost: true);

    return roomId;
  }

  static Stream<DatabaseEvent> getAllRooms() {
    return _roomsRef.orderByChild('isActive').equalTo(true).onValue;
  }

  static Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);
    final participantRef = roomRef.child('room_participants/${user.uid}');

    // Fetch the latest user profile from Firestore
    final userProfileDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;
    String displayId = '';

    if (userProfileDoc.exists) {
      final data = userProfileDoc.data() as Map<String, dynamic>;
      userName = data['displayName'] ?? userName;
      displayId = data['displayId'] ?? '';
      userPicture = data['photoUrl'] ?? data['profilePicture'] ?? userPicture;
    }

    // Add participant
    await participantRef.set({
      'userId': user.uid,
      'displayId': displayId,
      'userName': userName,
      'userPicture': userPicture,
      'isCoHost': false,
      'seatNo': -1,
      'joinedAt': ServerValue.timestamp,
      'isOnline': true,
      'isMuted': true,
    });

    // Increment participant count
    await roomRef.child('participantCount').set(ServerValue.increment(1));

    // --- CHANGED: Pass isHost: false ---
    await _setupPresence(roomId, user.uid, isHost: false);
  }

  // --- UPDATED METHOD ---
  static Future<void> _setupPresence(String roomId, String userId, {required bool isHost}) async {
    final participantRef = _roomsRef.child('$roomId/room_participants/$userId');
    final roomRef = _roomsRef.child(roomId);

    _currentParticipantRef = participantRef;

    _connectedRef.onValue.listen((event) async {
      if (event.snapshot.value == true) {
        // 1. Remove the participant entry on disconnect (Common for all)
        await participantRef.onDisconnect().remove();

        if (isHost) {
          // 2. IF HOST: Delete the entire room node on disconnect
          await roomRef.child('participantCount').onDisconnect().cancel();
          await roomRef.onDisconnect().remove();
        } else {
          // 3. IF GUEST: Only decrement the count on disconnect
          await roomRef.child('participantCount').onDisconnect().set(ServerValue.increment(-1));
        }

        // Set status to online while connected
        await participantRef.child('isOnline').set(true);
      }
    });
  }

  static Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);
    final participantRef = roomRef.child('room_participants/${user.uid}');

    // Cancel onDisconnect for this specific leaving action to prevent double counts/deletes
    // Note: In RTDB, you usually just perform the action immediately.
    // However, it is good practice to cancel the onDisconnect if you are handling it manually.
    await participantRef.onDisconnect().cancel();
    await roomRef.child('participantCount').onDisconnect().cancel();

    await participantRef.remove();
    await roomRef.child('participantCount').set(ServerValue.increment(-1));

    _currentParticipantRef = null;
  }

  static Future<void> deleteRoom(String roomId) async {
    final roomRef = _roomsRef.child(roomId);
    // Cancel onDisconnect to avoid conflicts (though deleting the node usually overrides it)
    await roomRef.onDisconnect().cancel();
    await roomRef.remove();
  }

  // ... (The rest of your existing methods: getRoomInfo, leaveSeat, etc. remain unchanged) ...

  static Future<DataSnapshot> getRoomInfo(String roomId) {
    return _roomsRef.child(roomId).get();
  }

  static Stream<DatabaseEvent> getRoomParticipants(String roomId) {
    return _roomsRef.child('$roomId/room_participants').orderByChild('joinedAt').onValue;
  }

  static Stream<DatabaseEvent> getRoomStream(String roomId) {
    return _roomsRef.child(roomId).onValue;
  }

  static Future<void> leaveSeat(String roomId) async {
    final user = _auth.currentUser!;
    await _roomsRef.child('$roomId/room_participants/${user.uid}').update({'seatNo': -1, 'isMuted': true});
  }

  static Future<void> stepDownFromCoHost(String roomId) async {
    final user = _auth.currentUser!;
    await _roomsRef.child('$roomId/room_participants/${user.uid}').update({'isCoHost': false, 'isMuted': true});
  }

  static Future<void> toggleMuteState(String roomId, bool newMuteState) async {
    final user = _auth.currentUser!;
    await _roomsRef.child('$roomId/room_participants/${user.uid}').update({'isMuted': newMuteState});
  }

  static Future<void> setRoomNotice(String roomId, String notice) async {
    await _roomsRef.child(roomId).update({'notice': notice});
  }

  static Future<void> moveSeat(String roomId, int newSeatNo) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);
    final participantRef = roomRef.child('room_participants/${user.uid}');

    final roomSnapshot = await roomRef.get();
    if (roomSnapshot.exists) {
      final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
      if (!(roomData['isMoveAllowed'] ?? true)) {
        throw Exception('Host has disabled moving seats.');
      }
    }

    final participantsSnapshot = await roomRef.child('room_participants').get();
    if (participantsSnapshot.exists) {
      final participants = participantsSnapshot.value as Map<dynamic, dynamic>;
      for (var participant in participants.values) {
        if (participant is Map && participant['seatNo'] == newSeatNo) {
          throw Exception('Seat is already occupied.');
        }
      }
    }

    await participantRef.update({'seatNo': newSeatNo, 'isCoHost': false});
  }

  static Future<void> takeSeat(String roomId, int newSeatNo) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);
    final participantRef = roomRef.child('room_participants/${user.uid}');

    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception('Room not found.');

    final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
    if (roomData['isSeatApprovalRequired'] ?? true) {
      throw Exception('Seat approval is required. Please send a request.');
    }

    final participantsSnapshot = await roomRef.child('room_participants').get();
    if (participantsSnapshot.exists) {
      final participants = participantsSnapshot.value as Map<dynamic, dynamic>;
      for (var participant in participants.values) {
        if (participant is Map && participant['seatNo'] == newSeatNo) {
          throw Exception('Seat is already occupied.');
        }
      }
    }

    await participantRef.update({'seatNo': newSeatNo, 'isMuted': false});
  }

  static Future<void> toggleMoveAllowed(String roomId, bool isAllowed) async {
    await _roomsRef.child(roomId).update({'isMoveAllowed': isAllowed});
  }

  static Future<void> toggleSeatApprovalRequired(String roomId, bool isRequired) async {
    await _roomsRef.child(roomId).update({'isSeatApprovalRequired': isRequired});
  }

  static Future<void> requestToBeSpeaker(String roomId) async {
    final user = _auth.currentUser!;
    final userProfileDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;

    if (userProfileDoc.exists) {
      final data = userProfileDoc.data() as Map<String, dynamic>;
      userName = data['displayName'] ?? userName;
      userPicture = data['photoUrl'] ?? data['profilePicture'] ?? userPicture;
    }

    await _roomsRef.child('$roomId/speaker_requests/${user.uid}').set({
      'userId': user.uid,
      'userName': userName,
      'userPicture': userPicture,
      'requestedAt': ServerValue.timestamp,
    });
  }

  static Stream<DatabaseEvent> getSpeakerRequestsStream(String roomId) {
    return _roomsRef.child('$roomId/speaker_requests').orderByChild('requestedAt').onValue;
  }

  static Future<void> approveSpeakerRequest(String roomId, String requestId, String userId) async {
    final roomRef = _roomsRef.child(roomId);
    final requestRef = roomRef.child('speaker_requests/$requestId');
    final participantRef = roomRef.child('room_participants/$userId');

    final participantsSnapshot = await roomRef.child('room_participants').get();
    final occupiedSeats = <int>{};

    if (participantsSnapshot.exists) {
      final participants = participantsSnapshot.value as Map<dynamic, dynamic>;
      for (var participant in participants.values) {
        if (participant is Map) {
          final seatNo = participant['seatNo'] as int?;
          if (seatNo != null && seatNo > 0) {
            occupiedSeats.add(seatNo);
          }
        }
      }
    }

    int? nextAvailableSeat;
    for (int i = 1; i <= 12; i++) {
      if (!occupiedSeats.contains(i)) {
        nextAvailableSeat = i;
        break;
      }
    }

    if (nextAvailableSeat == null) {
      await requestRef.remove();
      throw Exception('All seats are full.');
    }

    await participantRef.update({'seatNo': nextAvailableSeat, 'isMuted': false});
    await requestRef.remove();
  }

  static Future<void> rejectSpeakerRequest(String roomId, String requestId) async {
    await _roomsRef.child('$roomId/speaker_requests/$requestId').remove();
  }

  static Future<void> requestToBeCoHost(String roomId) async {
    final user = _auth.currentUser!;
    final userProfileDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;

    if (userProfileDoc.exists) {
      final data = userProfileDoc.data() as Map<String, dynamic>;
      userName = data['displayName'] ?? userName;
      userPicture = data['photoUrl'] ?? data['profilePicture'] ?? userPicture;
    }

    await _roomsRef.child('$roomId/cohost_requests/${user.uid}').set({
      'userId': user.uid,
      'userName': userName,
      'userPicture': userPicture,
      'requestedAt': ServerValue.timestamp,
    });
  }

  static Stream<DatabaseEvent> getCoHostRequestsStream(String roomId) {
    return _roomsRef.child('$roomId/cohost_requests').orderByChild('requestedAt').onValue;
  }

  static Future<void> approveCoHostRequest(String roomId, String requestId, String userId) async {
    final roomRef = _roomsRef.child(roomId);
    final requestRef = roomRef.child('cohost_requests/$requestId');
    final participantRef = roomRef.child('room_participants/$userId');

    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception('Room not found.');

    final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
    final hostId = roomData['hostId'];

    final participantsSnapshot = await roomRef.child('room_participants').get();
    if (participantsSnapshot.exists) {
      final participants = participantsSnapshot.value as Map<dynamic, dynamic>;
      for (var entry in participants.entries) {
        if (entry.key != hostId && entry.value is Map) {
          final participant = entry.value as Map<dynamic, dynamic>;
          if (participant['isCoHost'] == true) {
            await requestRef.remove();
            throw Exception('Co-host seat is already occupied.');
          }
        }
      }
    }

    await participantRef.update({'isCoHost': true, 'seatNo': -1, 'isMuted': false});
    await requestRef.remove();
  }

  static Future<void> rejectCoHostRequest(String roomId, String requestId) async {
    await _roomsRef.child('$roomId/cohost_requests/$requestId').remove();
  }

  static Future<void> setOrChangeRoomPassword(String roomId, String password) async {
    await _roomsRef.child(roomId).update({'isLocked': true, 'password': password});
  }

  static Future<void> removeRoomPassword(String roomId) async {
    await _roomsRef.child(roomId).update({'isLocked': false, 'password': null});
  }

  static Future<void> sendEmoji(String roomId, String emojiUrl, String emojiName) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);

    // --- NEW: Check if user is eligible to send emoji ---
    final participantSnapshot = await roomRef.child('room_participants/${user.uid}').get();

    if (!participantSnapshot.exists) {
      throw Exception('You must join the room first.');
    }

    final participantData = participantSnapshot.value as Map<dynamic, dynamic>;
    final int seatNo = participantData['seatNo'] ?? -1;
    final bool isCoHost = participantData['isCoHost'] ?? false;

    // Check if user is host
    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) {
      throw Exception('Room not found.');
    }

    final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
    final String hostId = roomData['hostId'] ?? '';
    final bool isHost = user.uid == hostId;

    // Only allow if user is host, co-host, or has a seat
    if (!isHost && !isCoHost && seatNo <= 0) {
      throw Exception('Only host, co-host, and seated participants can send emojis.');
    }

    String userName = participantData['userName'] ?? 'User';

    // --- CHANGED: Now includes senderId ---
    await roomRef.child('emoji_events').push().set({
      'senderId': user.uid,
      'senderName': userName,
      'emojiUrl': emojiUrl,
      'emojiName': emojiName,
      'timestamp': ServerValue.timestamp,
    });
  }

  static Stream<DatabaseEvent> getEmojiStream(String roomId) {
    return _roomsRef.child('$roomId/emoji_events').onChildAdded;
  }

  static Future<void> updateRoomBackground(String roomId, String backgroundUrl) async {
    await _roomsRef.child(roomId).update({
      'backgroundUrl': backgroundUrl,
      'backgroundUpdatedAt': ServerValue.timestamp,
    });
  }
}
