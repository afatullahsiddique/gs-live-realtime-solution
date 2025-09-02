import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  late FlutterSecureStorage storage;

  SecureStorage() {
    const aOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      preferencesKeyPrefix: "sge_",
      sharedPreferencesName: 'sge_preferences',
    );

    storage = const FlutterSecureStorage(aOptions: aOptions);
  }
}
