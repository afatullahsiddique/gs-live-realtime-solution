// greedy_game_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // <-- REQUIRED
import 'package:firebase_auth/firebase_auth.dart';

/// A simple data model to hold the result from our top earner query.
class TopEarner {
  final String userId;
  final int winningBet;

  TopEarner({required this.userId, required this.winningBet});
}

class GreedyGameService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance; // <-- REQUIRED

  /// Listens to the main control document.
  Stream<DocumentSnapshot> getGameControlsStream() {
    return _db.collection('gameControls').doc('main').snapshots();
  }

  /// Listens to the public state of a specific game round.
  Stream<DocumentSnapshot> getGameRoundStream(String roundId) {
    if (roundId == "0") return Stream.empty();
    return _db.collection('gameRounds').doc(roundId).snapshots();
  }

  /// Listens to the user's *own* bets for the current round.
  Stream<DocumentSnapshot> getMyBetsStream(String roundId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null || roundId == "0") return Stream.empty();
    return _db.collection('gameRounds').doc(roundId).collection('bets').doc(userId).snapshots();
  }

  /// Listens to the last 12 winning results.
  Stream<QuerySnapshot> getGameHistoryStream() {
    return _db
        .collection('gameRounds')
        .where('phase', isEqualTo: 'result')
        .orderBy('timestamp', descending: true)
        .limit(12)
        .snapshots();
  }

  /// [NEW] Sets the user's entire bet map by calling the 'placeGreedyBet' function.
  ///
  /// This replaces the old placeBet and removeBet.
  Future<void> setBets(String roundId, Map<int, int> bets) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // 1. Convert the Map<int, int> to Map<String, int> for Firebase
    // e.g., { 0: 100, 3: 50 } -> { "leaf_0": 100, "leaf_3": 50 }
    final Map<String, int> betsMap = bets.map((leafIndex, amount) {
      return MapEntry('leaf_$leafIndex', amount);
    });

    // 2. Get the callable function
    final callable = _functions.httpsCallable('placeGreedyBet');

    try {
      // 3. Call the function with the roundId and the complete bets map
      await callable.call({
        'roundId': roundId,
        'bets': betsMap,
      });
      print("[GREEDY_LOG] setBets successful.");
    } on FirebaseFunctionsException catch (e) {
      // Handle known errors from the cloud function
      print("[GREEDY_LOG] Error calling placeGreedyBet: ${e.code} - ${e.message}");
      throw Exception(e.message ?? "An error occurred placing your bet.");
    } catch (e) {
      // Handle other unknown errors
      print("[GREEDY_LOG] Generic error setting bets: $e");
      throw Exception("An unknown error occurred.");
    }
  }

  /// Fetches the top 3 users who won the most on a specific round.
  Future<List<TopEarner>> getTopEarners(String roundId, int winningIndex) async {
    if (roundId == "0") return [];

    final String leafKey = 'leaf_$winningIndex';

    try {
      final querySnap = await _db
          .collection('gameRounds')
          .doc(roundId)
          .collection('bets')
          .orderBy(leafKey, descending: true)
          .limit(3)
          .get();

      final List<TopEarner> earners = [];
      for (final doc in querySnap.docs) {
        final data = doc.data();
        final int winningBet = (data[leafKey] as int?) ?? 0;
        if (winningBet > 0) {
          earners.add(TopEarner(userId: doc.id, winningBet: winningBet));
        } else {
          break;
        }
      }
      return earners;
    } catch (e) {
      print("[GREEDY_LOG] ERROR fetching top earners: $e");
      print("[GREEDY_LOG] This likely means you need to create a Firestore Index.");
      return [];
    }
  }

  /// Adds the user to the game room's participant list
  Future<void> joinGameRoom(Map<String, dynamic> userMap) async {
    final docRef = _db.collection('gameControls').doc('main');
    await docRef.update({
      'participants': FieldValue.arrayUnion([userMap]),
    });
  }

  /// Removes the user from the game room's participant list
  Future<void> leaveGameRoom(Map<String, dynamic> userMap) async {
    final docRef = _db.collection('gameControls').doc('main');
    await docRef.update({
      'participants': FieldValue.arrayRemove([userMap]),
    });
  }
}