import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  static Future<void> syncUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _usersCollection.doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(userRef);

      if (!docSnapshot.exists) {
        final Map<String, dynamic> profileData = {
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'followerCount': 0,
          'followingCount': 0,
          'currentRoomId': null,
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
        transaction.update(userRef, updateData);
      }
    });
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

  /// Submits an application for an agency
  static Future<void> applyForAgency({
    required String agencyName,
    required String holderName,
    required String agencyId,
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

    // Create data map
    final Map<String, dynamic> applicationData = {
      'userId': currentUserId,
      'agencyName': agencyName,
      'holderName': holderName,
      'agencyId': agencyId,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'location': location,
      'locationFlag': locationFlag,
      'reference': reference,
      'nidFrontUrl': nidFrontUrl,
      'nidBackUrl': nidBackUrl,
      'status': 'pending', // Initial status
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await _agencyApplicationsCollection.doc(currentUserId).set(applicationData);
  }

  /// Submits an application for hosting
  /// UPDATED: removed agencyCardFile, added agencyCode (String)
  static Future<void> applyForHosting({
    required String idNumber,
    required String hostType,
    required String location,
    String? locationFlag,
    required String email,
    required String agencyCode, // Changed from File to String
    required File selfieFile,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user logged in");

    // Upload selfie only
    final selfieUrl = await _uploadApplicationDocument(currentUserId, selfieFile, 'selfie');

    // Create data map
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

  // ... Mutuals and List methods (omitted for brevity as they are unchanged)
  static Future<List<SimpleUser>> getMutualsList(String userId) async {
    // (Logic identical to your provided code)
    if (userId.isEmpty) return [];
    try {
      final List<SimpleUser> followingList = await getFollowingList(userId);
      if (followingList.isEmpty) return [];
      final List<Future<SimpleUser?>> mutualCheckFutures = [];
      for (final user in followingList) {
        final followerDocRef = _usersCollection.doc(userId).collection('followers').doc(user.id);
        final futureCheck = followerDocRef.get().then((doc) {
          return doc.exists ? user : null;
        });
        mutualCheckFutures.add(futureCheck);
      }
      final results = await Future.wait(mutualCheckFutures);
      return results.whereType<SimpleUser>().toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<SimpleUser>> getFollowingList(String userId) async {
    // (Logic identical to your provided code)
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
      rethrow;
    }
  }

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
      return null;
    }
  }
}
