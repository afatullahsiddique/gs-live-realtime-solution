import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SimpleUser {
  final String id;
  final String name;
  final String? pictureUrl;
  final String? currentRoomId;

  SimpleUser({required this.id, required this.name, this.pictureUrl, this.currentRoomId});
}

class ProfileService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _usersCollection = _firestore.collection('users');

  static Future<void> syncUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _usersCollection.doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(userRef);

      final Map<String, dynamic> profileData = {
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (!docSnapshot.exists) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
        profileData['followerCount'] = 0;
        profileData['followingCount'] = 0;
        profileData['currentRoomId'] = null;
        transaction.set(userRef, profileData);
      } else {
        // We only update non-null profile data
        // We do NOT set currentRoomId to null on login,
        // as they might be logging in on a second device.
        // Only the VideoRoomService should set this field to null.
        transaction.update(userRef, profileData);
      }
    });
  }

  static Stream<DocumentSnapshot> getUserProfileStream(String userId) {
    if (userId.isEmpty) {
      return Stream.empty();
    }
    return _usersCollection.doc(userId).snapshots();
  }

  static Stream<bool> isFollowing(String hostId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || hostId.isEmpty) {
      return Stream.value(false);
    }
    return _usersCollection
        .doc(currentUserId)
        .collection('following')
        .doc(hostId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  static Future<void> followUser(String hostId) async {
    final currentUserId = _auth.currentUser!.uid;
    await _usersCollection.doc(currentUserId).collection('following').doc(hostId).set({
      'followedAt': FieldValue.serverTimestamp(),
    });
    await _usersCollection.doc(hostId).collection('followers').doc(currentUserId).set({
      'followedAt': FieldValue.serverTimestamp(),
    });
    await _usersCollection.doc(hostId).update({'followerCount': FieldValue.increment(1)});
    await _usersCollection.doc(currentUserId).update({'followingCount': FieldValue.increment(1)});
  }

  static Future<void> unfollowUser(String hostId) async {
    final currentUserId = _auth.currentUser!.uid;
    await _usersCollection.doc(currentUserId).collection('following').doc(hostId).delete();
    await _usersCollection.doc(hostId).collection('followers').doc(currentUserId).delete();
    await _usersCollection.doc(hostId).update({'followerCount': FieldValue.increment(-1)});
    await _usersCollection.doc(currentUserId).update({'followingCount': FieldValue.increment(-1)});
  }

  /// Fetches a list of "mutuals" - users that the [userId] follows
  /// and who also follow [userId] back.
  /// (This function's logic does not need to change)
  static Future<List<SimpleUser>> getMutualsList(String userId) async {
    if (userId.isEmpty) return [];

    try {
      // 1. Get the list of people the current user follows.
      // This list will now contain SimpleUser objects WITH the currentRoomId.
      final List<SimpleUser> followingList = await getFollowingList(userId);
      if (followingList.isEmpty) {
        return [];
      }

      // 2. Create a list of futures to check for "follow back".
      final List<Future<SimpleUser?>> mutualCheckFutures = [];

      for (final user in followingList) {
        final followerDocRef = _usersCollection
            .doc(userId) // My user ID
            .collection('followers')
            .doc(user.id); // The ID of the person I'm checking

        final futureCheck = followerDocRef.get().then((doc) {
          if (doc.exists) {
            return user; // They follow me back, return the full SimpleUser
          } else {
            return null; // They don't, return null
          }
        });
        mutualCheckFutures.add(futureCheck);
      }

      // 3. Run all checks in parallel.
      final results = await Future.wait(mutualCheckFutures);

      // 4. Filter out the nulls and return the list.
      return results.whereType<SimpleUser>().toList();
    } catch (e) {
      print("Error fetching mutuals list: $e");
      rethrow;
    }
  }

  /// Fetches the list of users that the [userId] is following.
  /// (This function's logic does not need to change)
  static Future<List<SimpleUser>> getFollowingList(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final snapshot = await _usersCollection.doc(userId).collection('following').get();
      if (snapshot.docs.isEmpty) return [];

      List<Future<SimpleUser?>> futures = [];
      for (final doc in snapshot.docs) {
        futures.add(_fetchUser(doc.id));
      }

      final results = await Future.wait(futures);
      return results.whereType<SimpleUser>().toList();
    } catch (e) {
      print("Error fetching following list: $e");
      rethrow;
    }
  }

  /// Helper to fetch a single user's profile for the list
  static Future<SimpleUser?> _fetchUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;

      return SimpleUser(
        id: doc.id,
        name: data['displayName'] ?? data['hostName'] ?? 'No Name',
        pictureUrl: data['photoUrl'] ?? data['hostPicture'],
        currentRoomId: data['currentRoomId'],
      );
    } catch (e) {
      print("Error fetching user $userId: $e");
      return null;
    }
  }
}
