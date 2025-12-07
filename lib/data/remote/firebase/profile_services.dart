import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Simple model used for lists (mutuals/following)
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
  static final _storage = FirebaseStorage.instance;

  // Collection References
  static final _usersCollection = _firestore.collection('users');
  static final _agencyApplicationsCollection = _firestore.collection('agency_applications');
  static final _hostingApplicationsCollection = _firestore.collection('hosting_applications');
  static final _metadataCollection = _firestore.collection('system_metadata');

  /// Syncs the user profile.
  static Future<void> syncUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _usersCollection.doc(user.uid);
    final counterRef = _metadataCollection.doc('user_counters');

    try {
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final counterSnapshot = await transaction.get(counterRef);

        bool needsIdAssignment = !userSnapshot.exists;

        if (userSnapshot.exists) {
          final data = userSnapshot.data();
          if (data == null || !data.containsKey('displayId')) {
            needsIdAssignment = true;
          }
        }

        String? newDisplayId;

        if (needsIdAssignment) {
          int currentCount;
          if (counterSnapshot.exists) {
            currentCount = counterSnapshot.data()?['last_assigned_id'] ?? 100000;
          } else {
            currentCount = 100000;
          }

          final nextId = currentCount + 1;
          newDisplayId = nextId.toString();

          transaction.set(counterRef, {'last_assigned_id': nextId}, SetOptions(merge: true));
        }

        if (!userSnapshot.exists) {
          final Map<String, dynamic> profileData = {
            'uid': user.uid,
            'displayId': newDisplayId,
            'displayName': user.displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'lastLogin': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'followerCount': 0,
            'followingCount': 0,
            'balance': 0,
            'bio': '',
            'country': 'N/A',
            'countryFlagEmoji': null,
            'gender': null,
            'dob': null,
          };
          transaction.set(userRef, profileData);
        } else {
          final Map<String, dynamic> updateData = {'lastLogin': FieldValue.serverTimestamp(), 'email': user.email};

          if (newDisplayId != null) {
            updateData['displayId'] = newDisplayId;
          }

          transaction.update(userRef, updateData);
        }
      });
    } catch (e) {
      print("Error in syncUserProfile transaction: $e");
      rethrow;
    }
  }

  /// Uploads a profile image and returns the URL
  static Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      final uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print("Failed to upload profile image: $e");
      rethrow;
    }
  }

  /// Uploads an application document (NID, Selfie, etc.)
  static Future<String> _uploadApplicationDocument(String userId, File imageFile, String docName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('application_documents').child(userId).child('${docName}_$timestamp.jpg');

      final uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print("Failed to upload document: $e");
      rethrow;
    }
  }

  /// Updates user profile data
  static Future<void> updateUserProfile({
    String? displayName,
    String? country,
    String? countryFlagEmoji,
    String? gender,
    DateTime? dob,
    String? bio,
    File? imageFile,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception("No user logged in");
    }

    final Map<String, dynamic> dataToUpdate = {};

    if (displayName != null) dataToUpdate['displayName'] = displayName;
    if (country != null) dataToUpdate['country'] = country;
    if (countryFlagEmoji != null) dataToUpdate['countryFlagEmoji'] = countryFlagEmoji;
    if (gender != null) dataToUpdate['gender'] = gender;
    if (bio != null) dataToUpdate['bio'] = bio;
    if (dob != null) dataToUpdate['dob'] = Timestamp.fromDate(dob);

    if (imageFile != null) {
      final imageUrl = await _uploadProfileImage(currentUserId, imageFile);
      dataToUpdate['photoUrl'] = imageUrl;
    }

    if (dataToUpdate.isNotEmpty) {
      await _usersCollection.doc(currentUserId).update(dataToUpdate);
    }
  }

  /// Submits an application for an agency (removed agencyId parameter)
  static Future<void> applyForAgency({
    required String agencyName,
    required String holderName,
    required String email,
    required String whatsappNumber,
    required String location,
    String? locationFlag,
    String? reference,
    required File nidFrontFile,
    required File nidBackFile,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");

    // Upload images
    final nidFrontUrl = await _uploadApplicationDocument(currentUserId, nidFrontFile, 'nid_front');
    final nidBackUrl = await _uploadApplicationDocument(currentUserId, nidBackFile, 'nid_back');

    // Create data map (agencyId removed)
    final Map<String, dynamic> applicationData = {
      'userId': currentUserId,
      'agencyName': agencyName,
      'holderName': holderName,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'location': location,
      'locationFlag': locationFlag,
      'reference': reference,
      'nidFrontUrl': nidFrontUrl,
      'nidBackUrl': nidBackUrl,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await _agencyApplicationsCollection.doc(currentUserId).set(applicationData);
  }

  /// Cancels/Deletes the user's agency application (used for both cancel and re-apply)
  static Future<void> cancelAgencyApplication() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");

    await _agencyApplicationsCollection.doc(currentUserId).delete();
  }

  /// Submits an application for hosting
  static Future<void> applyForHosting({
    required String idNumber,
    required String hostType,
    required String location,
    String? locationFlag,
    required String email,
    required String agencyCode,
    required File selfieFile,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");

    final selfieUrl = await _uploadApplicationDocument(currentUserId, selfieFile, 'selfie');

    final Map<String, dynamic> applicationData = {
      'userId': currentUserId,
      'idNumber': idNumber,
      'hostType': hostType,
      'location': location,
      'locationFlag': locationFlag,
      'email': email,
      'agencyCode': agencyCode,
      'selfieUrl': selfieUrl,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await _hostingApplicationsCollection.doc(currentUserId).set(applicationData);
  }

  /// Gets the current user's agency application status
  static Future<DocumentSnapshot> getAgencyApplicationStatus() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");
    return _agencyApplicationsCollection.doc(currentUserId).get();
  }

  /// Gets the current user's hosting application status
  static Future<DocumentSnapshot> getHostingApplicationStatus() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");
    return _hostingApplicationsCollection.doc(currentUserId).get();
  }

  static Stream<DocumentSnapshot> getUserProfileStream(String userId) {
    if (userId.isEmpty) {
      return Stream.empty();
    }
    return _usersCollection.doc(userId).snapshots();
  }

  static Future<DocumentSnapshot> getUserProfile(String userId) {
    if (userId.isEmpty) {
      throw Exception("User ID cannot be empty");
    }
    return _usersCollection.doc(userId).get();
  }

  static Stream<QuerySnapshot> getFollowersStream(String userId) {
    if (userId.isEmpty) return Stream.empty();
    return _usersCollection.doc(userId).collection('followers').snapshots();
  }

  static Stream<QuerySnapshot> getFollowingsStream(String userId) {
    if (userId.isEmpty) return Stream.empty();
    return _usersCollection.doc(userId).collection('following').snapshots();
  }

  static Stream<bool> isFollowing(String hostId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || hostId.isEmpty) return Stream.value(false);
    return _usersCollection
        .doc(currentUserId)
        .collection('following')
        .doc(hostId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  static Future<void> followUser(String hostId) async {
    final currentUserId = _auth.currentUser!.uid;

    final batch = _firestore.batch();

    final followingRef = _usersCollection.doc(currentUserId).collection('following').doc(hostId);
    final followerRef = _usersCollection.doc(hostId).collection('followers').doc(currentUserId);
    final hostUserRef = _usersCollection.doc(hostId);
    final currentUserRef = _usersCollection.doc(currentUserId);

    batch.set(followingRef, {'followedAt': FieldValue.serverTimestamp()});
    batch.set(followerRef, {'followedAt': FieldValue.serverTimestamp()});
    batch.update(hostUserRef, {'followerCount': FieldValue.increment(1)});
    batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});

    await batch.commit();
  }

  static Future<void> unfollowUser(String hostId) async {
    final currentUserId = _auth.currentUser!.uid;

    final batch = _firestore.batch();

    final followingRef = _usersCollection.doc(currentUserId).collection('following').doc(hostId);
    final followerRef = _usersCollection.doc(hostId).collection('followers').doc(currentUserId);
    final hostUserRef = _usersCollection.doc(hostId);
    final currentUserRef = _usersCollection.doc(currentUserId);

    batch.delete(followingRef);
    batch.delete(followerRef);
    batch.update(hostUserRef, {'followerCount': FieldValue.increment(-1)});
    batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  // ✅ UPDATED: Get mutuals list (people who follow you AND you follow back)
  static Future<List<SimpleUser>> getMutualsList(String userId) async {
    if (userId.isEmpty) return [];

    try {
      print('🔍 Getting mutuals for user: $userId');

      // Step 1: Get all users that current user is following
      final followingSnapshot = await _usersCollection.doc(userId).collection('following').get();

      if (followingSnapshot.docs.isEmpty) {
        print('❌ User is not following anyone');
        return [];
      }

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      print('✅ Following ${followingIds.length} users: $followingIds');

      // Step 2: Check which of those users also follow current user back (mutuals)
      final List<Future<SimpleUser?>> mutualCheckFutures = [];

      for (final followingId in followingIds) {
        final futureCheck = _usersCollection.doc(userId).collection('followers').doc(followingId).get().then((
          followerDoc,
        ) async {
          // If they follow you back, fetch their profile
          if (followerDoc.exists) {
            print('✅ $followingId is a mutual friend');
            return await _fetchUser(followingId);
          } else {
            print('❌ $followingId does not follow back');
          }
          return null;
        });

        mutualCheckFutures.add(futureCheck);
      }

      final results = await Future.wait(mutualCheckFutures);
      final mutuals = results.whereType<SimpleUser>().toList();
      print('✅ Total mutuals found: ${mutuals.length}');

      return mutuals;
    } catch (e) {
      print("❌ Error in getMutualsList: $e");
      rethrow;
    }
  }

  // ✅ Get all users you're following
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
      print("Error in getFollowingList: $e");
      rethrow;
    }
  }

  // ✅ Get all your followers
  static Future<List<SimpleUser>> getFollowersList(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final snapshot = await _usersCollection.doc(userId).collection('followers').get();

      if (snapshot.docs.isEmpty) return [];

      List<Future<SimpleUser?>> futures = [];
      for (final doc in snapshot.docs) {
        futures.add(_fetchUser(doc.id));
      }

      final results = await Future.wait(futures);
      return results.whereType<SimpleUser>().toList();
    } catch (e) {
      print("Error in getFollowersList: $e");
      rethrow;
    }
  }

  // ✅ UPDATED: Fetch user WITHOUT currentRoomId (will be fetched from RTDB separately)
  static Future<SimpleUser?> _fetchUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return SimpleUser(
        id: doc.id,
        name: data['displayName'] ?? data['hostName'] ?? 'No Name',
        pictureUrl: data['photoUrl'] ?? data['hostPicture'],
        currentRoomId: null, // ✅ Don't use Firestore currentRoomId anymore
      );
    } catch (e) {
      print("Error fetching user $userId: $e");
      return null;
    }
  }

  /// Deducts balance from sender and adds diamonds to recipients
  static Future<void> sendGift({required int giftValue, required List<String> recipientIds}) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");

    final int totalCost = giftValue * recipientIds.length;

    try {
      await _firestore.runTransaction((transaction) async {
        final senderDoc = await transaction.get(_usersCollection.doc(currentUserId));
        if (!senderDoc.exists) throw Exception("Sender profile not found");

        final senderData = senderDoc.data() as Map<String, dynamic>;
        final int currentBalance = senderData['balance'] ?? 0;

        if (currentBalance < totalCost) {
          throw Exception("Insufficient balance. Need $totalCost beans, have $currentBalance beans.");
        }

        transaction.update(_usersCollection.doc(currentUserId), {'balance': FieldValue.increment(-totalCost)});

        for (String recipientId in recipientIds) {
          transaction.update(_usersCollection.doc(recipientId), {'diamonds': FieldValue.increment(giftValue)});
        }
      });
    } catch (e) {
      print("Error in sendGift transaction: $e");
      rethrow;
    }
  }

  /// Get current user's balance
  static Future<int> getCurrentUserBalance() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return 0;

    try {
      final doc = await _usersCollection.doc(currentUserId).get();
      if (!doc.exists) return 0;
      final data = doc.data() as Map<String, dynamic>;
      return data['balance'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream of current user's balance
  static Stream<int> getCurrentUserBalanceStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value(0);

    return _usersCollection.doc(currentUserId).snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['balance'] ?? 0;
    });
  }
}
