import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cute_live/data/remote/firebase/profile_services.dart';

import '../../../ui/video_streaming/bottomsheets/invite_pk_bottomsheet.dart';

class VideoRoomService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final _usersCollection = _firestore.collection('users');
  static final _roomsCollection = _firestore.collection('video_rooms');

  static Future<String> createRoom() async {
    final user = _auth.currentUser!;
    final roomRef = _roomsCollection.doc();
    final participantRef = roomRef.collection('participants').doc(user.uid);
    final userRef = _usersCollection.doc(user.uid);

    final batch = _firestore.batch();

    batch.set(roomRef, {
      'hostId': user.uid,
      'hostName': user.displayName ?? 'Anonymous',
      'hostPicture': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'participantCount': 1, // Total users in room
      'onCallCount': 1,      // <-- NEW: Users on call
      'isLocked': false,
      'password': null,
      'pkState': {'isPK': false},
    });

    batch.set(participantRef, {
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPicture': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'isMuted': false,
      'isCameraOn': true,
      'onCall': true, // <-- NEW
    });

    batch.update(userRef, {'currentRoomId': roomRef.id});

    await batch.commit();
    return roomRef.id;
  }

  static Stream<QuerySnapshot> getAllRooms() {
    return _roomsCollection.where('isActive', isEqualTo: true).snapshots();
  }

  // This function is now for viewers to join (they are NOT on call)
  static Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsCollection.doc(roomId);
    final participantRef = roomRef.collection('participants').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist.");

      final roomData = roomSnapshot.data() as Map<String, dynamic>;
      final pkState = roomData['pkState'] as Map<String, dynamic>? ?? {'isPK': false};

      if (pkState['isPK'] == true) {
        throw Exception("Cannot join room: PK battle is in progress.");
      }

      final participantSnapshot = await transaction.get(participantRef);
      if (!participantSnapshot.exists) {
        transaction.set(participantRef, {
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous',
          'userPicture': user.photoURL,
          'joinedAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'isMuted': true,
          'isCameraOn': false,
          'onCall': false,
        });

        transaction.update(roomRef, {'participantCount': FieldValue.increment(1)});
      }
    });
  }

  static Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsCollection.doc(roomId);
    final participantRef = roomRef.collection('participants').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final participantDoc = await transaction.get(participantRef);
      if (participantDoc.exists) {
        final participantData = participantDoc.data() as Map<String, dynamic>;
        final bool wasOnCall = participantData['onCall'] ?? false;

        transaction.delete(participantRef);

        final roomUpdateData = {'participantCount': FieldValue.increment(-1)};

        if (wasOnCall) {
          roomUpdateData['onCallCount'] = FieldValue.increment(-1);
        }

        transaction.update(roomRef, roomUpdateData);
      }
    });
  }

  static Future<void> deleteRoom(String roomId) async {
    final roomDocRef = _roomsCollection.doc(roomId);

    String? hostId;
    Map<String, dynamic> pkState = {'isPK': false};

    try {
      final roomDoc = await roomDocRef.get();
      if (roomDoc.exists) {
        final data = roomDoc.data() as Map<String, dynamic>;
        hostId = data['hostId'];
        pkState = data['pkState'] ?? {'isPK': false};
      }
    } catch (e) {
      print("Error getting room info before delete: $e");
    }

    // --- NEW: If in PK, end it first ---
    if (pkState['isPK'] == true && pkState.containsKey('opponentRoomId')) {
      try {
        await endPKBattle(roomId, pkState['opponentRoomId']);
      } catch (e) {
        print("Error ending PK battle during room deletion: $e");
      }
    }
    // ---

    final participants = await roomDocRef.collection('participants').get();
    final joinRequests = await roomDocRef.collection('join_requests').get();
    final pkInvites = await roomDocRef.collection('pk_invites').get();

    final batch = _firestore.batch();

    for (var doc in participants.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in joinRequests.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in pkInvites.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(roomDocRef);

    if (hostId != null) {
      final userRef = _usersCollection.doc(hostId);
      batch.update(userRef, {'currentRoomId': null});
    }

    await batch.commit();
  }

  static Future<void> toggleMuteState(String roomId, bool newMuteState) async {
    final user = _auth.currentUser!;
    await _roomsCollection.doc(roomId).collection('participants').doc(user.uid).update({
      'isMuted': newMuteState,
    });
  }

  static Future<void> toggleCameraState(String roomId, bool isCameraOn) async {
    final user = _auth.currentUser!;
    await _roomsCollection.doc(roomId).collection('participants').doc(user.uid).update({
      'isCameraOn': isCameraOn,
    });
  }

  static Future<DocumentSnapshot> getRoomInfo(String roomId) {
    return _roomsCollection.doc(roomId).get();
  }

  static Stream<QuerySnapshot> getRoomParticipants(String roomId) {
    return _roomsCollection.doc(roomId).collection('participants').orderBy('joinedAt').snapshots();
  }

  static Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _roomsCollection.doc(roomId).snapshots();
  }

  static Future<void> requestToJoin(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _roomsCollection.doc(roomId);

    // Check if room is in PK before allowing request
    final roomDoc = await roomRef.get();
    if (roomDoc.exists) {
      final data = roomDoc.data() as Map<String, dynamic>;
      final pkState = data['pkState'] as Map<String, dynamic>? ?? {'isPK': false};
      if (pkState['isPK'] == true) {
        throw Exception("Cannot join room: PK battle is in progress.");
      }
    } else {
      throw Exception("Room does not exist.");
    }

    await roomRef.collection('join_requests').doc(user.uid).set({
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPicture': user.photoURL,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getJoinRequestsStream(String roomId) {
    return _roomsCollection.doc(roomId).collection('join_requests').orderBy('requestedAt').snapshots();
  }

  static Future<void> approveJoinRequest(String roomId, String requestId, String userId) async {
    final roomRef = _roomsCollection.doc(roomId);
    final requestRef = roomRef.collection('join_requests').doc(requestId);
    final participantRef = roomRef.collection('participants').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist.");

      final roomData = roomSnapshot.data() as Map<String, dynamic>;
      final currentOnCallCount = roomData['onCallCount'] ?? 0;
      final pkState = roomData['pkState'] as Map<String, dynamic>? ?? {'isPK': false};

      if (pkState['isPK'] == true) {
        throw Exception("Cannot approve request: PK battle is in progress.");
      }

      // Use the onCallCount for the limit
      if (currentOnCallCount >= 4) {
        throw Exception("The room is full. Cannot approve more participants.");
      }

      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) throw Exception("Request no longer exists.");

      // This is now an UPDATE, not a SET
      // We are "promoting" a viewer to be on-call
      transaction.update(participantRef, {
        'isMuted': false,
        'isCameraOn': true,
        'onCall': true, // <-- NEW: Promote user to on-call
      });

      // Increment ONLY the onCallCount
      transaction.update(roomRef, {'onCallCount': FieldValue.increment(1)});
      transaction.delete(requestRef);
    });
  }

  static Future<void> rejectJoinRequest(String roomId, String requestId) async {
    await _roomsCollection.doc(roomId).collection('join_requests').doc(requestId).delete();
  }

  static Future<void> sendPKInvite({
    required String senderRoomId,
    required SimpleUser receiverUser,
    required int durationInMinutes,
  }) async {
    final user = _auth.currentUser!;
    final receiverRoomId = receiverUser.currentRoomId;
    if (receiverRoomId == null) {
      throw Exception("${receiverUser.name} is not in a room.");
    }

    final receiverRoomDoc = await _roomsCollection.doc(receiverRoomId).get();
    if (receiverRoomDoc.exists) {
      final data = receiverRoomDoc.data() as Map<String, dynamic>;
      final pkState = data['pkState'] as Map<String, dynamic>? ?? {'isPK': false};
      if (pkState['isPK'] == true) {
        throw Exception("${receiverUser.name} is already in a PK battle.");
      }
    } else {
      throw Exception("${receiverUser.name}'s room does not exist.");
    }
    // ---

    final inviteRef = _roomsCollection.doc(receiverRoomId).collection('pk_invites').doc(senderRoomId);

    await inviteRef.set({
      'senderRoomId': senderRoomId,
      'senderHostId': user.uid,
      'senderHostName': user.displayName ?? 'Anonymous',
      'senderHostPicture': user.photoURL,
      'receiverRoomId': receiverRoomId,
      'receiverHostId': receiverUser.id,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'durationInMinutes': durationInMinutes, // --- NEW ---
    });
  }

  static Stream<List<PKInvite>> getPKInvitesStream(String myRoomId) {
    return _roomsCollection
        .doc(myRoomId)
        .collection('pk_invites')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PKInvite.fromFirestore(doc)).toList());
  }

  /// REQUIRES A FIRESTORE INDEX (Collection Group: 'pk_invites')
  /// 1. senderRoomId (Ascending)
  /// 2. status (Ascending)
  static Stream<List<PKInvite>> getSentPKInvitesStream(String mySenderRoomId) {
    return _firestore
        .collectionGroup('pk_invites')
        .where('senderRoomId', isEqualTo: mySenderRoomId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PKInvite.fromFirestore(doc)).toList());
  }

  static Future<void> acceptPKInvite(String myRoomId, PKInvite invite) async {
    final batch = _firestore.batch();
    final myRoomRef = _roomsCollection.doc(myRoomId);
    final senderRoomRef = _roomsCollection.doc(invite.senderRoomId);

    final myRoomDoc = await myRoomRef.get();
    final myRoomData = myRoomDoc.data() as Map<String, dynamic>;

    final int duration = invite.durationInMinutes;
    final pkEndTime = Timestamp.fromDate(DateTime.now().add(Duration(minutes: duration)));


    batch.update(myRoomRef, {
      'pkState': {
        'isPK': true,
        'opponentRoomId': invite.senderRoomId,
        'opponentHostId': invite.senderHostId,
        'opponentHostName': invite.senderHostName,
        'role': 'receiver',
        'durationInMinutes': duration,
        'pkEndTime': pkEndTime,
      }
    });

    batch.update(senderRoomRef, {
      'pkState': {
        'isPK': true,
        'opponentRoomId': myRoomId,
        'opponentHostId': myRoomData['hostId'],
        'opponentHostName': myRoomData['hostName'],
        'role': 'sender',
        'durationInMinutes': duration,
        'pkEndTime': pkEndTime,
      }
    });

    final inviteRef = myRoomRef.collection('pk_invites').doc(invite.id);
    batch.update(inviteRef, {'status': 'accepted'});

    await batch.commit();
  }

  static Future<void> rejectPKInvite(String myRoomId, PKInvite invite) async {
    await _roomsCollection.doc(myRoomId).collection('pk_invites').doc(invite.id).delete();
  }

  static Future<void> endPKBattle(String myRoomId, String opponentRoomId) async {
    final batch = _firestore.batch();

    // 1. Clear my PK state
    final myRoomRef = _roomsCollection.doc(myRoomId);
    batch.update(myRoomRef, {'pkState': {'isPK': false}});

    // 2. Clear the opponent's PK state
    final opponentRoomRef = _roomsCollection.doc(opponentRoomId);
    batch.update(opponentRoomRef, {'pkState': {'isPK': false}});

    // 3. Clean up the 'accepted' invite docs from both rooms
    final myInvitesRef = myRoomRef.collection('pk_invites').doc(opponentRoomId);
    batch.delete(myInvitesRef);

    final opponentInvitesRef = opponentRoomRef.collection('pk_invites').doc(myRoomId);
    batch.delete(opponentInvitesRef);

    await batch.commit();
  }

  // This function is now less relevant as endPKBattle is more specific
  static Future<void> clearPKInvite(PKInvite invite) async {
    // This is called by the SENDER after the PK is over
    final data =
    await _roomsCollection.doc(invite.receiverRoomId).collection('pk_invites').doc(invite.id).get();

    if (data.exists) {
      await data.reference.delete();
    }
  }
}

