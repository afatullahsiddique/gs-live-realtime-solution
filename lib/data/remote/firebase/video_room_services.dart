import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoRoomService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> createRoom() async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('video_rooms').doc();
    final participantRef = roomRef.collection('participants').doc(user.uid);

    final batch = _firestore.batch();

    batch.set(roomRef, {
      'hostId': user.uid,
      'hostName': user.displayName ?? 'Anonymous',
      'hostPicture': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'participantCount': 1,
      'isLocked': false,
      'password': null,
    });

    batch.set(participantRef, {
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPicture': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'isMuted': false,
      'isCameraOn': true,
    });

    await batch.commit();
    return roomRef.id;
  }

  static Stream<QuerySnapshot> getAllRooms() {
    return _firestore.collection('video_rooms').where('isActive', isEqualTo: true).snapshots();
  }

  static Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('video_rooms').doc(roomId);
    final participantRef = roomRef.collection('participants').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist.");

      final currentCount = roomSnapshot.data()?['participantCount'] ?? 0;
      if (currentCount >= 4) {
        throw Exception("This room is full.");
      }

      transaction.set(participantRef, {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userPicture': user.photoURL,
        'joinedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isMuted': true,
        'isCameraOn': false,
      });

      transaction.update(roomRef, {'participantCount': FieldValue.increment(1)});
    });
  }

  static Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('video_rooms').doc(roomId);
    final participantRef = roomRef.collection('participants').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final participantDoc = await transaction.get(participantRef);
      if (participantDoc.exists) {
        transaction.delete(participantRef);
        transaction.update(roomRef, {'participantCount': FieldValue.increment(-1)});
      }
    });
  }

  static Future<void> deleteRoom(String roomId) async {
    final roomDocRef = _firestore.collection('video_rooms').doc(roomId);
    final participants = await roomDocRef.collection('participants').get();
    final joinRequests = await roomDocRef.collection('join_requests').get();
    final batch = _firestore.batch();

    for (var doc in participants.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in joinRequests.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(roomDocRef);
    await batch.commit();
  }

  static Future<void> toggleMuteState(String roomId, bool newMuteState) async {
    final user = _auth.currentUser!;
    await _firestore.collection('video_rooms').doc(roomId).collection('participants').doc(user.uid).update({
      'isMuted': newMuteState,
    });
  }

  static Future<void> toggleCameraState(String roomId, bool isCameraOn) async {
    final user = _auth.currentUser!;
    await _firestore.collection('video_rooms').doc(roomId).collection('participants').doc(user.uid).update({
      'isCameraOn': isCameraOn,
    });
  }

  static Future<DocumentSnapshot> getRoomInfo(String roomId) {
    return _firestore.collection('video_rooms').doc(roomId).get();
  }

  static Stream<QuerySnapshot> getRoomParticipants(String roomId) {
    return _firestore.collection('video_rooms').doc(roomId).collection('participants').orderBy('joinedAt').snapshots();
  }

  static Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('video_rooms').doc(roomId).snapshots();
  }

  static Future<void> requestToJoin(String roomId) async {
    final user = _auth.currentUser!;
    await _firestore.collection('video_rooms').doc(roomId).collection('join_requests').doc(user.uid).set({
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPicture': user.photoURL,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getJoinRequestsStream(String roomId) {
    return _firestore
        .collection('video_rooms')
        .doc(roomId)
        .collection('join_requests')
        .orderBy('requestedAt')
        .snapshots();
  }

  // MODIFIED: This function is now fixed.
  static Future<void> approveJoinRequest(String roomId, String requestId, String userId) async {
    final roomRef = _firestore.collection('video_rooms').doc(roomId);
    final requestRef = roomRef.collection('join_requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist.");

      final currentCount = roomSnapshot.data()?['participantCount'] ?? 0;
      if (currentCount >= 4) {
        throw Exception("The room is full. Cannot approve more participants.");
      }

      // **THE FIX IS HERE**
      // 1. Get the data from the request document itself.
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) throw Exception("Request no longer exists.");
      final requestData = requestSnapshot.data() as Map<String, dynamic>;

      // 2. Use that data to create the new participant.
      final participantRef = roomRef.collection('participants').doc(userId);
      transaction.set(participantRef, {
        'userId': userId,
        // Use the name and picture from the request, not from a separate fetch.
        'userName': requestData['userName'] ?? 'Anonymous',
        'userPicture': requestData['userPicture'],
        'joinedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isMuted': false,
        'isCameraOn': true,
      });

      // 3. Update the room count and delete the processed request.
      transaction.update(roomRef, {'participantCount': FieldValue.increment(1)});
      transaction.delete(requestRef);
    });
  }

  static Future<void> rejectJoinRequest(String roomId, String requestId) async {
    await _firestore.collection('video_rooms').doc(roomId).collection('join_requests').doc(requestId).delete();
  }
}

