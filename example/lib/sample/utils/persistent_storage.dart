part of 'rapid_kit_sample_util.dart';

class SharedPreferencesUtil {
  SharedPreferencesUtil._privateConstructor();
  static final SharedPreferencesUtil instance =
      SharedPreferencesUtil._privateConstructor();
  Future<void> setString(String key, String value) async =>
      await PreferencesStoreChannel.putString(key, value);
  Future<String?> getString(String key) async =>
      await PreferencesStoreChannel.getString(key, '');
  Future<void> setInt(String key, int value) async =>
      await PreferencesStoreChannel.putInt(key, value);
  Future<int?> getInt(String key, [int defaultValue = 0]) async =>
      await PreferencesStoreChannel.getInt(key, defaultValue);
  Future<void> setBool(String key, bool value) async =>
      await PreferencesStoreChannel.putBool(key, value);
  Future<bool?> getBool(String key) async =>
      await PreferencesStoreChannel.getBool(key, false);
  Future<void> remove(String key) async =>
      await PreferencesStoreChannel.remove(key);
}
