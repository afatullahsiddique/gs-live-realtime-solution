import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveStreamService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> createRoom() async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('live_streams').doc();
    final participantRef = roomRef.collection('participants').doc(user.uid);

    final batch = _firestore.batch();

    // Host room data
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

    // Host participant data
    batch.set(participantRef, {
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPicture': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'isMuted': false,
      'isCameraOn': true, // Host camera is ON
    });

    await batch.commit();
    return roomRef.id;
  }

  static Stream<QuerySnapshot> getAllRooms() {
    return _firestore.collection('live_streams').where('isActive', isEqualTo: true).snapshots();
  }

  static Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('live_streams').doc(roomId);
    final participantRef = roomRef.collection('participants').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist.");

      final currentCount = roomSnapshot.data()?['participantCount'] ?? 0;
      // Host + 4 Guests = 5 total
      if (currentCount >= 5) {
        throw Exception("This room is full.");
      }

      transaction.set(participantRef, {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userPicture': user.photoURL,
        'joinedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isMuted': true,
        'isCameraOn': false, // Guest camera is OFF
      });

      transaction.update(roomRef, {'participantCount': FieldValue.increment(1)});
    });
  }

  static Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('live_streams').doc(roomId);
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
    final roomDocRef = _firestore.collection('live_streams').doc(roomId);
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
    await _firestore.collection('live_streams').doc(roomId).collection('participants').doc(user.uid).update({
      'isMuted': newMuteState,
    });
  }

  // Only the host will use this
  static Future<void> toggleCameraState(String roomId, bool isCameraOn) async {
    final user = _auth.currentUser!;
    await _firestore.collection('live_streams').doc(roomId).collection('participants').doc(user.uid).update({
      'isCameraOn': isCameraOn,
    });
  }

  static Future<DocumentSnapshot> getRoomInfo(String roomId) {
    return _firestore.collection('live_streams').doc(roomId).get();
  }

  static Stream<QuerySnapshot> getRoomParticipants(String roomId) {
    return _firestore.collection('live_streams').doc(roomId).collection('participants').orderBy('joinedAt').snapshots();
  }

  static Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('live_streams').doc(roomId).snapshots();
  }

  static Future<void> requestToJoin(String roomId) async {
    final user = _auth.currentUser!;
    await _firestore.collection('live_streams').doc(roomId).collection('join_requests').doc(user.uid).set({
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userPicture': user.photoURL,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getJoinRequestsStream(String roomId) {
    return _firestore
        .collection('live_streams')
        .doc(roomId)
        .collection('join_requests')
        .orderBy('requestedAt')
        .snapshots();
  }

  static Future<void> approveJoinRequest(String roomId, String requestId, String userId) async {
    final roomRef = _firestore.collection('live_streams').doc(roomId);
    final requestRef = roomRef.collection('join_requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist.");

      final currentCount = roomSnapshot.data()?['participantCount'] ?? 0;
      // Host + 4 Guests = 5 total
      if (currentCount >= 5) {
        throw Exception("The room is full. Cannot approve more participants.");
      }

      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) throw Exception("Request no longer exists.");
      final requestData = requestSnapshot.data() as Map<String, dynamic>;

      final participantRef = roomRef.collection('participants').doc(userId);
      transaction.set(participantRef, {
        'userId': userId,
        'userName': requestData['userName'] ?? 'Anonymous',
        'userPicture': requestData['userPicture'],
        'joinedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isMuted': true, // Guest joins muted by default
        'isCameraOn': false, // **CRITICAL CHANGE**: Guest camera is OFF
      });

      transaction.update(roomRef, {'participantCount': FieldValue.increment(1)});
      transaction.delete(requestRef);
    });
  }

  static Future<void> rejectJoinRequest(String roomId, String requestId) async {
    await _firestore.collection('live_streams').doc(roomId).collection('join_requests').doc(requestId).delete();
  }
}