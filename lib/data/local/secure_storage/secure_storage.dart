import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../ui/auth/login/login_state.dart';

class SecureStorage {
  late FlutterSecureStorage storage;

  SecureStorage() {
    const aOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      preferencesKeyPrefix: "cute_",
      sharedPreferencesName: 'cute_preferences',
    );

    storage = const FlutterSecureStorage(aOptions: aOptions);
  }

  static const String userKey = 'current_user';

  Future<void> setUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await storage.write(key: userKey, value: userJson);
  }

  Future<User?> getUser() async {
    final userJson = await storage.read(key: userKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    }
    return null;
  }

  Future<String?> getToken() async {
    final user = await getUser();
    return user?.token; // ✅ Now exists
  }


  // Check if logged in
  Future<bool> get isLoggedIn async {
    return await getUser() != null;
  }

  // Logout
  Future<void> logout() async {
    return await storage.delete(key: userKey);
  }
}
