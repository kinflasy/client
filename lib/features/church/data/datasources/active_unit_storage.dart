import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActiveUnitStorage {
  ActiveUnitStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  }) : _storage = storage;

  static const selectedChurchUnitIdKey = 'selected_church_unit_id';

  final FlutterSecureStorage _storage;

  Future<String?> readSelectedUnitId() {
    return _storage.read(key: selectedChurchUnitIdKey);
  }

  Future<void> saveSelectedUnitId(String unitId) {
    return _storage.write(key: selectedChurchUnitIdKey, value: unitId);
  }

  Future<void> clearSelectedUnitId() {
    return _storage.delete(key: selectedChurchUnitIdKey);
  }
}
