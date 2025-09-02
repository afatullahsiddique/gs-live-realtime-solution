import 'package:cute_live/data/local/secure_storage/secure_storage.dart';

extension UserSecureStorage on SecureStorage {
  static const String loggedInKey = 'is_logged_in';

  Future<void> setIsLoggedIn(bool isLoggedIn) async {
    return await storage.write(key: loggedInKey, value: isLoggedIn.toString());
  }

  Future<bool> get getIsLoggedIn async {
    return (await storage.read(key: loggedInKey) ?? "false") == "true";
  }
}
