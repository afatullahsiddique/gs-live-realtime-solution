import 'package:cloud_firestore/cloud_firestore.dart';

class AppServices {
  static final _firestore = FirebaseFirestore.instance;

  // Collection Reference
  static final _appSettingsCollection = _firestore.collection('appSettings');

  // The specific document ID where we store Zego keys
  static const String _zegoDocId = 'zego_config';

  /// Fetches the Zego App ID as an integer
  static Future<int> getZegoAppId() async {
    try {
      final doc = await _appSettingsCollection.doc(_zegoDocId).get();

      if (doc.exists && doc.data() != null) {
        return (doc.data()!['appId'] as num).toInt();
      } else {
        return 423730354; // Default from user
      }
    } catch (e) {
      print("Error fetching Zego App ID: $e");
      return 423730354;
    }
  }

  /// Fetches the Zego App Sign as a String
  static Future<String> getZegoAppSign() async {
    try {
      final doc = await _appSettingsCollection.doc(_zegoDocId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['appSign'] as String;
      } else {
        return "cec0bbcfd59fcadabe5511c354ffe19d6fe71a470ad75f177d2712bf25b3734b"; // Default from user
      }
    } catch (e) {
      print("Error fetching Zego App Sign: $e");
      return "cec0bbcfd59fcadabe5511c354ffe19d6fe71a470ad75f177d2712bf25b3734b";
    }
  }

  /// Optional: Get both at once to save a database read
  static Future<Map<String, dynamic>> getZegoConfig() async {
    final doc = await _appSettingsCollection.doc(_zegoDocId).get();
    if (doc.exists && doc.data() != null) {
      return doc.data() as Map<String, dynamic>;
    }
    throw Exception("Zego config not found");
  }
}
