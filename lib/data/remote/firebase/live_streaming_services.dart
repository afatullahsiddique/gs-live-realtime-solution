import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../ui/video_streaming/bottomsheets/invite_pk_bottomsheet.dart';

/// Service class for managing live streaming rooms using Firebase RTDB and Firestore
class LiveStreamService {
  // Firebase Instances
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection & Reference Paths
  static final _usersCollection = _firestore.collection('users');
  static final DatabaseReference _roomsRef = _database.ref('live_streams');
  static final DatabaseReference _connectedRef = _database.ref('.info/connected');
  static final DatabaseReference _globalRandomPKRef = _database.ref('globalRandomLivePKInvites');

  // ============================================================================
  // ROOM MANAGEMENT
  // ============================================================================

  /// Creates a new live stream room and returns the room ID
  static Future<String> createRoom() async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.push();
    final roomId = roomRef.key!;

    final userDoc = await _usersCollection.doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception("User profile not found. Cannot create room.");
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String hostName = userData['displayName'] ?? 'Anonymous';
    final String? hostPicture = userData['photoUrl'];
    final String displayId = userData['displayId'] ?? '';

    await roomRef.set({
      'hostId': user.uid,
      'hostDisplayId': displayId,
      'hostName': hostName,
      'hostPicture': hostPicture,
      'createdAt': ServerValue.timestamp,
      'isActive': true,
      'participantCount': 1,
      'isLocked': false,
      'password': null,
    });

    final participantRef = roomRef.child('participants/${user.uid}');
    await participantRef.set({
      'userId': user.uid,
      'displayId': displayId,
      'userName': hostName,
      'userPicture': hostPicture,
      'joinedAt': ServerValue.timestamp,
      'isOnline': true,
      'isMuted': false,
      'isCameraOn': true,
    });

    await _setupPresence(roomId, user.uid, isHost: true);

    return roomId;
  }

  /// Gets a stream of all active rooms
  static Stream<DatabaseEvent> getAllRooms() {
    return _roomsRef.orderByChild('isActive').equalTo(true).onValue;
  }

  /// Gets room information for a specific room ID
  static Future<DataSnapshot> getRoomInfo(String roomId) {
    return _roomsRef.child(roomId).get();
  }

  /// Gets a stream of room data changes
  static Stream<DatabaseEvent> getRoomStream(String roomId) {
    return _roomsRef.child(roomId).onValue;
  }

  /// Deletes a room completely
  static Future<void> deleteRoom(String roomId) async {
    final roomRef = _roomsRef.child(roomId);
    await roomRef.onDisconnect().cancel();
    await roomRef.remove();
  }

  // ============================================================================
  // PARTICIPANT MANAGEMENT
  // ============================================================================

  /// Joins an existing room as a participant
  static Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);
    final participantRef = roomRef.child('participants/${user.uid}');

    final userDoc = await _usersCollection.doc(user.uid).get();
    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;
    String displayId = '';

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['displayName'] ?? userName;
      displayId = userData['displayId'] ?? '';
      userPicture = userData['photoUrl'] ?? userData['userPicture'] ?? userPicture;
    }

    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception("Room does not exist.");

    final currentCount = (roomSnapshot.value as Map<dynamic, dynamic>)['participantCount'] ?? 0;
    if (currentCount >= 5) {
      throw Exception("This room is full.");
    }

    await participantRef.set({
      'userId': user.uid,
      'displayId': displayId,
      'userName': userName,
      'userPicture': userPicture,
      'joinedAt': ServerValue.timestamp,
      'isOnline': true,
      'isMuted': true,
      'isCameraOn': false,
    });

    await roomRef.child('participantCount').set(ServerValue.increment(1));
    await _setupPresence(roomId, user.uid, isHost: false);
  }

  /// Leaves a room as a participant
  static Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);
    final participantRef = roomRef.child('participants/${user.uid}');

    await participantRef.onDisconnect().cancel();
    await roomRef.child('participantCount').onDisconnect().cancel();

    final participantSnapshot = await participantRef.get();
    if (participantSnapshot.exists) {
      await participantRef.remove();
      await roomRef.child('participantCount').set(ServerValue.increment(-1));
    }
  }

  /// Gets a stream of participants in a room
  static Stream<DatabaseEvent> getRoomParticipants(String roomId) {
    return _roomsRef.child('$roomId/participants').orderByChild('joinedAt').onValue;
  }

  /// Sets up presence detection for connected/disconnected users
  static Future<void> _setupPresence(String roomId, String userId, {required bool isHost}) async {
    final participantRef = _roomsRef.child('$roomId/participants/$userId');
    final roomRef = _roomsRef.child(roomId);

    _connectedRef.onValue.listen((event) async {
      if (event.snapshot.value == true) {
        if (isHost) {
          await roomRef.child('participantCount').onDisconnect().cancel();
          await roomRef.onDisconnect().remove();
        } else {
          await participantRef.onDisconnect().remove();
          await roomRef.child('participantCount').onDisconnect().set(ServerValue.increment(-1));
        }
        await participantRef.child('isOnline').set(true);
      }
    });
  }

  /// Mutes all participants except the host (used during PK battles)
  static Future<void> demoteAllParticipantsToViewers(String roomId, String hostId) async {
    final participantsRef = _roomsRef.child('$roomId/participants');

    try {
      final participantsSnapshot = await participantsRef.get();
      if (!participantsSnapshot.exists) return;

      final participants = participantsSnapshot.value as Map<dynamic, dynamic>;

      for (final entry in participants.entries) {
        if (entry.key != hostId) {
          await participantsRef.child(entry.key).update({'isMuted': true});
        }
      }
    } catch (e) {
      print("Error demoting participants: $e");
    }
  }

  // ============================================================================
  // PARTICIPANT STATE MANAGEMENT
  // ============================================================================

  /// Toggles mute state for current user
  static Future<void> toggleMuteState(String roomId, bool newMuteState) async {
    final user = _auth.currentUser!;
    await _roomsRef.child('$roomId/participants/${user.uid}').update({'isMuted': newMuteState});
  }

  /// Toggles camera state for current user
  static Future<void> toggleCameraState(String roomId, bool isCameraOn) async {
    final user = _auth.currentUser!;
    await _roomsRef.child('$roomId/participants/${user.uid}').update({'isCameraOn': isCameraOn});
  }

  // ============================================================================
  // JOIN REQUESTS
  // ============================================================================

  /// Sends a request to join a room
  static Future<void> requestToJoin(String roomId) async {
    final user = _auth.currentUser!;
    final userDoc = await _usersCollection.doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;
    String displayId = '';

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['displayName'] ?? userName;
      displayId = userData['displayId'] ?? '';
      userPicture = userData['photoUrl'] ?? userData['userPicture'] ?? userPicture;
    }

    await _roomsRef.child('$roomId/join_requests/${user.uid}').set({
      'userId': user.uid,
      'displayId': displayId,
      'userName': userName,
      'userPicture': userPicture,
      'requestedAt': ServerValue.timestamp,
    });
  }

  /// Gets a stream of join requests for a room
  static Stream<DatabaseEvent> getJoinRequestsStream(String roomId) {
    return _roomsRef.child('$roomId/join_requests').orderByChild('requestedAt').onValue;
  }

  /// Approves a join request
  static Future<void> approveJoinRequest(String roomId, String requestId, String userId) async {
    final roomRef = _roomsRef.child(roomId);
    final requestRef = roomRef.child('join_requests/$requestId');

    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) throw Exception("Room does not exist.");

    final currentCount = (roomSnapshot.value as Map<dynamic, dynamic>)['participantCount'] ?? 0;
    if (currentCount >= 5) {
      throw Exception("The room is full. Cannot approve more participants.");
    }

    final requestSnapshot = await requestRef.get();
    if (!requestSnapshot.exists) throw Exception("Request no longer exists.");
    final requestData = requestSnapshot.value as Map<dynamic, dynamic>;

    final participantRef = roomRef.child('participants/$userId');
    await participantRef.set({
      'userId': userId,
      'userName': requestData['userName'] ?? 'Anonymous',
      'userPicture': requestData['userPicture'],
      'joinedAt': ServerValue.timestamp,
      'isOnline': true,
      'isMuted': true,
      'isCameraOn': false,
    });

    await roomRef.child('participantCount').set(ServerValue.increment(1));
    await _setupPresence(roomId, userId, isHost: false);
    await requestRef.remove();
  }

  /// Rejects a join request
  static Future<void> rejectJoinRequest(String roomId, String requestId) async {
    await _roomsRef.child('$roomId/join_requests/$requestId').remove();
  }

  // ============================================================================
  // EMOJI SYSTEM
  // ============================================================================

  /// Sends an emoji to the room
  static Future<void> sendEmoji(String roomId, String emojiUrl, String emojiName) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsRef.child(roomId);

    final roomSnapshot = await roomRef.get();
    if (!roomSnapshot.exists) {
      throw Exception("Room does not exist.");
    }

    final participantRef = roomRef.child('participants/${user.uid}');
    final participantSnapshot = await participantRef.get();

    if (!participantSnapshot.exists) {
      throw Exception("You must join the audio call to send emojis.");
    }

    final userDoc = await _usersCollection.doc(user.uid).get();
    String userName = user.displayName ?? 'Anonymous';

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['displayName'] ?? userName;
    }

    await roomRef.child('emoji').set({
      'senderId': user.uid,
      'senderName': userName,
      'emojiUrl': emojiUrl,
      'emojiName': emojiName,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Gets a stream of emoji events in a room
  static Stream<DatabaseEvent> getEmojiStream(String roomId) {
    return _roomsRef.child('$roomId/emoji').onValue;
  }

  // ============================================================================
  // USER ROOM QUERIES
  // ============================================================================

  /// Finds the active room where the user is the host
  static Future<String?> getUserActiveRoom(String userId) async {
    try {
      final snapshot = await _roomsRef.get();
      if (!snapshot.exists) return null;

      final allRooms = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in allRooms.entries) {
        try {
          final roomId = entry.key.toString();
          final dynamic roomValue = entry.value;

          if (roomValue is! Map) continue;

          final roomData = roomValue as Map<dynamic, dynamic>;
          final hostId = roomData['hostId']?.toString();
          final isActive = roomData['isActive'];

          if (hostId == userId && isActive == true) {
            return roomId;
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      print("Error checking user active livestream: $e");
      return null;
    }
  }

  /// Finds any room where the user is present (as host or participant)
  static Future<String?> getUserCurrentRoom(String userId) async {
    try {
      final hostingRoom = await getUserActiveRoom(userId);
      if (hostingRoom != null) return hostingRoom;

      final snapshot = await _roomsRef.get();
      if (!snapshot.exists) return null;

      final rooms = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in rooms.entries) {
        try {
          final roomId = entry.key.toString();
          final roomData = entry.value;

          if (roomData is Map && roomData['isActive'] == true) {
            final participantsSnapshot = await _roomsRef.child('$roomId/participants/$userId').get();
            if (participantsSnapshot.exists) {
              return roomId;
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      print("Error checking user current livestream: $e");
      return null;
    }
  }

  // ============================================================================
  // PK BATTLE SYSTEM
  // ============================================================================

  /// Sends a PK battle invite to another user
  static Future<void> sendPKInvite({
    required String senderRoomId,
    required String receiverUserId,
    required int durationInMinutes,
  }) async {
    final user = _auth.currentUser!;
    final receiverRoomId = await getUserActiveRoom(receiverUserId);

    if (receiverRoomId == null) {
      throw Exception("User is not in a room.");
    }

    final receiverRoomSnapshot = await _roomsRef.child(receiverRoomId).get();
    if (receiverRoomSnapshot.exists) {
      final data = receiverRoomSnapshot.value as Map<dynamic, dynamic>;
      final pkState = data['pkState'] as Map<dynamic, dynamic>? ?? {'isPK': false};
      if (pkState['isPK'] == true) {
        throw Exception("User is already in a PK battle.");
      }
    } else {
      throw Exception("User's room does not exist.");
    }

    final inviteRef = _roomsRef.child('$receiverRoomId/pk_invites/$senderRoomId');

    await inviteRef.set({
      'senderRoomId': senderRoomId,
      'senderHostId': user.uid,
      'senderHostName': user.displayName ?? 'Anonymous',
      'senderHostPicture': user.photoURL,
      'receiverRoomId': receiverRoomId,
      'receiverHostId': receiverUserId,
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
      'durationInMinutes': durationInMinutes,
    });
  }

  /// Gets a stream of pending PK invites for a room
  static Stream<List<PKInvite>> getPKInvitesStream(String myRoomId) {
    return _roomsRef.child('$myRoomId/pk_invites').orderByChild('status').equalTo('pending').onValue.map((event) {
      if (!event.snapshot.exists) return <PKInvite>[];

      final invitesMap = event.snapshot.value as Map<dynamic, dynamic>;
      return invitesMap.entries.map((entry) => PKInvite.fromRTDB(entry.key, entry.value)).toList();
    });
  }

  /// Gets a stream of sent PK invites (currently returns empty)
  static Stream<List<PKInvite>> getSentPKInvitesStream(String mySenderRoomId) {
    return Stream.value([]);
  }

  /// Accepts a PK battle invite
  static Future<void> acceptPKInvite(String myRoomId, PKInvite invite) async {
    final myRoomRef = _roomsRef.child(myRoomId);
    final senderRoomRef = _roomsRef.child(invite.senderRoomId);

    final myRoomSnapshot = await myRoomRef.get();
    final myRoomData = myRoomSnapshot.value as Map<dynamic, dynamic>;

    final int duration = invite.durationInMinutes;
    final pkEndTime = DateTime.now().add(Duration(minutes: duration)).millisecondsSinceEpoch;

    await myRoomRef.update({
      'pkState': {
        'isPK': true,
        'opponentRoomId': invite.senderRoomId,
        'opponentHostId': invite.senderHostId,
        'opponentHostName': invite.senderHostName,
        'role': 'receiver',
        'durationInMinutes': duration,
        'pkEndTime': pkEndTime,
      },
    });

    await senderRoomRef.update({
      'pkState': {
        'isPK': true,
        'opponentRoomId': myRoomId,
        'opponentHostId': myRoomData['hostId'],
        'opponentHostName': myRoomData['hostName'],
        'role': 'sender',
        'durationInMinutes': duration,
        'pkEndTime': pkEndTime,
      },
    });

    final inviteRef = myRoomRef.child('pk_invites/${invite.id}');
    await inviteRef.update({'status': 'accepted'});
  }

  /// Rejects a PK battle invite
  static Future<void> rejectPKInvite(String myRoomId, PKInvite invite) async {
    await _roomsRef.child('$myRoomId/pk_invites/${invite.id}').remove();
  }

  /// Ends a PK battle between two rooms
  static Future<void> endPKBattle(String myRoomId, String opponentRoomId) async {
    await _roomsRef.child(myRoomId).update({
      'pkState': {'isPK': false},
    });
    await _roomsRef.child(opponentRoomId).update({
      'pkState': {'isPK': false},
    });
    await _roomsRef.child('$myRoomId/pk_invites/$opponentRoomId').remove();
    await _roomsRef.child('$opponentRoomId/pk_invites/$myRoomId').remove();
  }

  // ============================================================================
  // RANDOM PK SYSTEM
  // ============================================================================

  /// Sends a random PK invite globally
  static Future<void> sendRandomPKInvite({required String senderRoomId, required int durationInMinutes}) async {
    final user = _auth.currentUser!;

    final senderRoomSnapshot = await _roomsRef.child(senderRoomId).get();
    if (!senderRoomSnapshot.exists) {
      throw Exception('Your room does not exist.');
    }

    final senderRoomData = senderRoomSnapshot.value as Map<dynamic, dynamic>;
    final pkState = senderRoomData['pkState'] as Map<dynamic, dynamic>? ?? {'isPK': false};

    if (pkState['isPK'] == true) {
      throw Exception('You are already in a PK battle.');
    }

    final inviteRef = _globalRandomPKRef.push();
    final inviteId = inviteRef.key!;

    await inviteRef.set({
      'inviteId': inviteId,
      'senderRoomId': senderRoomId,
      'senderHostId': user.uid,
      'senderHostName': senderRoomData['hostName'] ?? (user.displayName ?? 'Anonymous'),
      'senderHostPicture': senderRoomData['hostPicture'] ?? user.photoURL,
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
      'durationInMinutes': durationInMinutes,
      'expiresAt': DateTime.now().add(const Duration(seconds: 7)).millisecondsSinceEpoch,
    });

    // Auto-delete after 7 seconds if still pending
    Future.delayed(const Duration(seconds: 7), () async {
      try {
        final snapshot = await inviteRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (data['status'] == 'pending') {
            await inviteRef.remove();
          }
        }
      } catch (e) {
        print('Error auto-deleting random PK invite: $e');
      }
    });
  }

  /// Gets a stream of global random PK invites
  static Stream<List<PKInvite>> getGlobalRandomPKInvitesStream() {
    return _globalRandomPKRef.onValue.map((event) {
      if (!event.snapshot.exists) return <PKInvite>[];

      final dynamic value = event.snapshot.value;
      if (value == null || value is! Map) return <PKInvite>[];

      final invitesMap = Map<dynamic, dynamic>.from(value);

      return invitesMap.entries.where((entry) => entry.value is Map).map((entry) {
        final inviteData = Map<dynamic, dynamic>.from(entry.value as Map);
        return PKInvite(
          id: entry.key.toString(),
          senderRoomId: inviteData['senderRoomId'] ?? '',
          senderHostId: inviteData['senderHostId'] ?? '',
          senderHostName: inviteData['senderHostName'] ?? 'Unknown',
          senderHostPicture: inviteData['senderHostPicture'],
          receiverRoomId: '',
          receiverHostId: '',
          durationInMinutes: inviteData['durationInMinutes'] ?? 5,
          isRandom: true,
        );
      }).toList();
    });
  }

  /// Accepts a global random PK invite
  static Future<void> acceptGlobalRandomPKInvite(String roomId, PKInvite invite) async {
    final user = _auth.currentUser!;

    final senderRoomSnapshot = await _roomsRef.child(invite.senderRoomId).get();
    if (!senderRoomSnapshot.exists) {
      throw Exception('Sender room no longer exists.');
    }

    final senderRoomData = senderRoomSnapshot.value as Map<dynamic, dynamic>;
    final senderPkState = senderRoomData['pkState'] as Map<dynamic, dynamic>? ?? {'isPK': false};

    if (senderPkState['isPK'] == true) {
      throw Exception('PK already started with someone else.');
    }

    final myRoomSnapshot = await _roomsRef.child(roomId).get();
    if (myRoomSnapshot.exists) {
      final myRoomData = myRoomSnapshot.value as Map<dynamic, dynamic>;
      final myPkState = myRoomData['pkState'] as Map<dynamic, dynamic>? ?? {'isPK': false};

      if (myPkState['isPK'] == true) {
        throw Exception('You are already in a PK battle.');
      }
    }

    await _globalRandomPKRef.child(invite.id).remove();

    final pkEndTime = DateTime.now().add(Duration(minutes: invite.durationInMinutes));

    final receiverDoc = await _usersCollection.doc(user.uid).get();
    final receiverName = receiverDoc.data()?['displayName'] ?? 'Unknown';
    final receiverPicture = receiverDoc.data()?['profilePicture'];

    await _roomsRef.child(roomId).child('pkState').set({
      'isPK': true,
      'opponentRoomId': invite.senderRoomId,
      'opponentHostId': invite.senderHostId,
      'opponentHostName': invite.senderHostName,
      'opponentHostPicture': invite.senderHostPicture,
      'pkEndTime': pkEndTime.millisecondsSinceEpoch,
      'role': 'receiver',
    });

    await _roomsRef.child(invite.senderRoomId).child('pkState').set({
      'isPK': true,
      'opponentRoomId': roomId,
      'opponentHostId': user.uid,
      'opponentHostName': receiverName,
      'opponentHostPicture': receiverPicture,
      'pkEndTime': pkEndTime.millisecondsSinceEpoch,
      'role': 'sender',
    });
  }
}
