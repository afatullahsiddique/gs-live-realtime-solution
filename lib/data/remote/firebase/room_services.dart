import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final _usersCollection = _firestore.collection('users');

  static Future<String> createRoom({String? password}) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('rooms').doc();
    final participantRef = roomRef.collection('room_participants').doc(user.uid);

    final userRef = _usersCollection.doc(user.uid);

    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw Exception("User profile not found. Cannot create room.");
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String hostName = userData['displayName'] ?? 'Anonymous';
    final String? hostPicture = userData['photoUrl'];

    final batch = _firestore.batch();

    final bool isLocked = password != null && password.isNotEmpty;

    batch.set(roomRef, {
      'hostId': user.uid,
      'hostName': hostName,
      'hostPicture': hostPicture,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'participantCount': 1,
      'isMoveAllowed': true,
      'isSeatApprovalRequired': true,
      'isLocked': isLocked,
      'password': isLocked ? password : null,
    });

    batch.set(participantRef, {
      'userId': user.uid,
      'userName': hostName,
      'userPicture': hostPicture,
      'isCoHost': true,
      'seatNo': 0,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'isMuted': false,
    });

    await batch.commit();
    return roomRef.id;
  }

  static Stream<QuerySnapshot> getAllRooms() {
    return _firestore.collection('rooms').where('isActive', isEqualTo: true).snapshots();
  }

  static Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final participantRef = roomRef.collection('room_participants').doc(user.uid);

    // 1. Fetch the latest user profile from Firestore 'users' collection
    final userProfileDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;

    // 2. If the document exists, override the Auth data with Firestore data
    if (userProfileDoc.exists) {
      final data = userProfileDoc.data() as Map<String, dynamic>;
      userName = data['displayName'] ?? userName;
      userPicture = data['photoUrl'] ?? data['profilePicture'] ?? userPicture;
    }

    final batch = _firestore.batch();

    // 3. Write this Firestore data into the room participant entry
    batch.set(participantRef, {
      'userId': user.uid,
      'userName': userName, // Now comes from Firestore
      'userPicture': userPicture, // Now comes from Firestore
      'isCoHost': false,
      'seatNo': -1,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'isMuted': true,
    });

    batch.update(roomRef, {'participantCount': FieldValue.increment(1)});
    await batch.commit();
  }

  static Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final participantRef = roomRef.collection('room_participants').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final participantDoc = await transaction.get(participantRef);
      if (participantDoc.exists) {
        transaction.delete(participantRef);
        transaction.update(roomRef, {'participantCount': FieldValue.increment(-1)});
      }
    });
  }

  static Future<void> deleteRoom(String roomId) async {
    final roomDocRef = _firestore.collection('rooms').doc(roomId);
    final participants = await roomDocRef.collection('room_participants').get();
    final speakerRequests = await roomDocRef.collection('speaker_requests').get();
    final coHostRequests = await roomDocRef.collection('cohost_requests').get();
    final batch = _firestore.batch();

    for (var doc in participants.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in speakerRequests.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in coHostRequests.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(roomDocRef);
    await batch.commit();
  }

  static Future<DocumentSnapshot> getRoomInfo(String roomId) {
    return _firestore.collection('rooms').doc(roomId).get();
  }

  static Stream<QuerySnapshot> getRoomParticipants(String roomId) {
    return _firestore.collection('rooms').doc(roomId).collection('room_participants').orderBy('joinedAt').snapshots();
  }

  static Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots();
  }

  static Future<void> leaveSeat(String roomId) async {
    final user = _auth.currentUser!;
    await _firestore.collection('rooms').doc(roomId).collection('room_participants').doc(user.uid).update({
      'seatNo': -1,
      'isMuted': true,
    });
  }

  static Future<void> stepDownFromCoHost(String roomId) async {
    final user = _auth.currentUser!;
    await _firestore.collection('rooms').doc(roomId).collection('room_participants').doc(user.uid).update({
      'isCoHost': false,
      'isMuted': true,
    });
  }

  static Future<void> toggleMuteState(String roomId, bool newMuteState) async {
    final user = _auth.currentUser!;
    await _firestore.collection('rooms').doc(roomId).collection('room_participants').doc(user.uid).update({
      'isMuted': newMuteState,
    });
  }

  static Future<void> moveSeat(String roomId, int newSeatNo) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final participantRef = roomRef.collection('room_participants').doc(user.uid);

    final roomDoc = await roomRef.get();
    if (roomDoc.exists && !(roomDoc.data()?['isMoveAllowed'] ?? true)) {
      throw Exception('Host has disabled moving seats.');
    }

    final query = roomRef.collection('room_participants').where('seatNo', isEqualTo: newSeatNo);
    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      throw Exception('Seat is already occupied.');
    } else {
      await participantRef.update({'seatNo': newSeatNo, 'isCoHost': false});
    }
  }

  /// NEW: A guest (listener) takes an empty seat.
  static Future<void> takeSeat(String roomId, int newSeatNo) async {
    final user = _auth.currentUser!;
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final participantRef = roomRef.collection('room_participants').doc(user.uid);

    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) throw Exception('Room not found.');

    // Check the new room setting
    if (roomDoc.data()?['isSeatApprovalRequired'] ?? true) {
      throw Exception('Seat approval is required. Please send a request.');
    }

    // Check if seat is occupied
    final query = roomRef.collection('room_participants').where('seatNo', isEqualTo: newSeatNo);
    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      throw Exception('Seat is already occupied.');
    } else {
      // Assign seat and unmute
      await participantRef.update({'seatNo': newSeatNo, 'isMuted': false});
    }
  }

  static Future<void> toggleMoveAllowed(String roomId, bool isAllowed) async {
    await _firestore.collection('rooms').doc(roomId).update({'isMoveAllowed': isAllowed});
  }

  /// NEW: Toggle the setting for requiring seat approval
  static Future<void> toggleSeatApprovalRequired(String roomId, bool isRequired) async {
    await _firestore.collection('rooms').doc(roomId).update({'isSeatApprovalRequired': isRequired});
  }

  // ## MODIFIED: Fetches latest user profile data before request ##
  static Future<void> requestToBeSpeaker(String roomId) async {
    final user = _auth.currentUser!;

    // Fetch latest data from Firestore
    final userProfileDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;

    if (userProfileDoc.exists) {
      final data = userProfileDoc.data() as Map<String, dynamic>;
      userName = data['displayName'] ?? userName;
      userPicture = data['photoUrl'] ?? data['profilePicture'] ?? userPicture;
    }

    await _firestore.collection('rooms').doc(roomId).collection('speaker_requests').doc(user.uid).set({
      'userId': user.uid,
      'userName': userName,
      'userPicture': userPicture,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getSpeakerRequestsStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).collection('speaker_requests').orderBy('requestedAt').snapshots();
  }

  static Future<void> approveSpeakerRequest(String roomId, String requestId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final requestRef = roomRef.collection('speaker_requests').doc(requestId);
    final participantRef = roomRef.collection('room_participants').doc(userId);

    final participantsSnapshot = await roomRef.collection('room_participants').get();
    final occupiedSeats = participantsSnapshot.docs
        .map((doc) => (doc.data())['seatNo'] as int)
        .where((seatNo) => seatNo > 0)
        .toSet();

    int? nextAvailableSeat;
    for (int i = 1; i <= 12; i++) {
      if (!occupiedSeats.contains(i)) {
        nextAvailableSeat = i;
        break;
      }
    }

    if (nextAvailableSeat == null) {
      await requestRef.delete();
      throw Exception('All seats are full.');
    }

    final batch = _firestore.batch();
    batch.update(participantRef, {'seatNo': nextAvailableSeat, 'isMuted': false});
    batch.delete(requestRef);
    await batch.commit();
  }

  static Future<void> rejectSpeakerRequest(String roomId, String requestId) async {
    await _firestore.collection('rooms').doc(roomId).collection('speaker_requests').doc(requestId).delete();
  }

  // ## MODIFIED: Fetches latest user profile data before request (Consistency) ##
  static Future<void> requestToBeCoHost(String roomId) async {
    final user = _auth.currentUser!;

    // Fetch latest data from Firestore
    final userProfileDoc = await _firestore.collection('users').doc(user.uid).get();

    String userName = user.displayName ?? 'Anonymous';
    String? userPicture = user.photoURL;

    if (userProfileDoc.exists) {
      final data = userProfileDoc.data() as Map<String, dynamic>;
      userName = data['displayName'] ?? userName;
      userPicture = data['photoUrl'] ?? data['profilePicture'] ?? userPicture;
    }

    await _firestore.collection('rooms').doc(roomId).collection('cohost_requests').doc(user.uid).set({
      'userId': user.uid,
      'userName': userName,
      'userPicture': userPicture,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getCoHostRequestsStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).collection('cohost_requests').orderBy('requestedAt').snapshots();
  }

  static Future<void> approveCoHostRequest(String roomId, String requestId, String userId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final requestRef = roomRef.collection('cohost_requests').doc(requestId);
    final participantRef = roomRef.collection('room_participants').doc(userId);
    final roomDoc = await roomRef.get();
    final hostId = roomDoc.data()?['hostId'];
    final coHostsSnapshot = await roomRef.collection('room_participants').where('isCoHost', isEqualTo: true).get();
    final otherCoHosts = coHostsSnapshot.docs.where((doc) => doc.id != hostId);

    if (otherCoHosts.isNotEmpty) {
      await requestRef.delete();
      throw Exception('Co-host seat is already occupied.');
    }

    final batch = _firestore.batch();
    batch.update(participantRef, {'isCoHost': true, 'seatNo': -1, 'isMuted': false});
    batch.delete(requestRef);
    await batch.commit();
  }

  static Future<void> rejectCoHostRequest(String roomId, String requestId) async {
    await _firestore.collection('rooms').doc(roomId).collection('cohost_requests').doc(requestId).delete();
  }

  static Future<void> setOrChangeRoomPassword(String roomId, String password) async {
    await _firestore.collection('rooms').doc(roomId).update({'isLocked': true, 'password': password});
  }

  static Future<void> removeRoomPassword(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({'isLocked': false, 'password': null});
  }
}
