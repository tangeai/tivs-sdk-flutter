part of 'rapid_kit_sample_channel.dart';

class PreferencesStoreChannel {
  static MethodChannel? _preferenceMethodChannel;
  static bool get _usesFileStore => Platform.isWindows || Platform.isLinux;

  static void _initializeChannel() {
    _preferenceMethodChannel ??= MethodChannel(
      'com.tange.ai/rapid_kit_example/method.channel/preference_store',
    );
  }

  static Future<void> putInt(String key, int value) async {
    if (_usesFileStore) {
      await PreferencesFileStore.putInt(key, value);
      return;
    }
    _initializeChannel();
    await _preferenceMethodChannel!.invokeMethod<void>(
      'putPreferencesInt',
      <String, dynamic>{'key': key, 'value': value},
    );
  }

  static Future<int> getInt(String key, int defaultValue) async {
    if (_usesFileStore) {
      return await PreferencesFileStore.getInt(key, defaultValue);
    }
    _initializeChannel();
    final int? result = await _preferenceMethodChannel!.invokeMethod<int>(
      'getPreferencesInt',
      <String, dynamic>{'key': key, 'defaultValue': defaultValue},
    );
    if (result != null) {
      return result;
    } else {
      throw Exception('Expected int but got null');
    }
  }

  static Future<void> putString(String key, String value) async {
    if (_usesFileStore) {
      await PreferencesFileStore.putString(key, value);
      return;
    }
    _initializeChannel();
    await _preferenceMethodChannel!.invokeMethod<void>(
      'putPreferencesString',
      <String, dynamic>{'key': key, 'value': value},
    );
  }

  static Future<String> getString(String key, String defaultValue) async {
    if (_usesFileStore) {
      return await PreferencesFileStore.getString(key, defaultValue);
    }
    _initializeChannel();
    final String? result = await _preferenceMethodChannel!.invokeMethod<String>(
      'getPreferencesString',
      <String, dynamic>{'key': key, 'defaultValue': defaultValue},
    );
    if (result != null) {
      return result;
    } else {
      throw Exception('Expected String but got null');
    }
  }

  static Future<void> putBool(String key, bool value) async {
    if (_usesFileStore) {
      await PreferencesFileStore.putBool(key, value);
      return;
    }
    _initializeChannel();
    await _preferenceMethodChannel!.invokeMethod<void>(
      'putPreferencesBool',
      <String, dynamic>{'key': key, 'value': value},
    );
  }

  static Future<bool> getBool(String key, bool defaultValue) async {
    if (_usesFileStore) {
      return await PreferencesFileStore.getBool(key, defaultValue);
    }
    _initializeChannel();
    final bool? result = await _preferenceMethodChannel!.invokeMethod<bool>(
      'getPreferencesBool',
      <String, dynamic>{'key': key, 'defaultValue': defaultValue},
    );
    if (result != null) {
      return result;
    } else {
      throw Exception('Expected bool but got null');
    }
  }

  static Future<void> remove(String key) async {
    if (_usesFileStore) {
      await PreferencesFileStore.remove(key);
      return;
    }
    _initializeChannel();
    await _preferenceMethodChannel!.invokeMethod<void>(
      'removePreferencesKey',
      <String, dynamic>{'key': key},
    );
  }
}

/// Write each key as a single file in the desktop application directory.
/// The file content is the value of the key.
class PreferencesFileStore {
  static Future<String> _getDirectoryPath() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['USERPROFILE'];
      if (appData != null) {
        return '$appData\\.RapitKitExample\\preferences';
      }
    }
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home/.rapid_kit_example/preferences';
      }
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> _ensureDirectoryExists() async {
    final path = await _getDirectoryPath();
    final directory = Directory(path);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
  }

  static Future<String> _getFilePath(String key) async {
    final directoryPath = await _getDirectoryPath();
    return '$directoryPath${Platform.pathSeparator}$key';
  }

  static Future<void> putInt(String key, int value) async {
    await _ensureDirectoryExists();
    final path = await _getFilePath(key);
    final file = File(path);
    await file.writeAsString(value.toString());
  }

  static Future<int> getInt(String key, int defaultValue) async {
    final path = await _getFilePath(key);
    final file = File(path);
    if (!file.existsSync()) {
      return defaultValue;
    }
    final content = await file.readAsString();
    return int.tryParse(content) ?? defaultValue;
  }

  static Future<void> putString(String key, String value) async {
    await _ensureDirectoryExists();
    final path = await _getFilePath(key);
    final file = File(path);
    await file.writeAsString(value);
  }

  static Future<String> getString(String key, String defaultValue) async {
    final path = await _getFilePath(key);
    final file = File(path);
    if (!file.existsSync()) {
      return defaultValue;
    }
    return await file.readAsString();
  }

  static Future<void> putBool(String key, bool value) async {
    await _ensureDirectoryExists();
    final path = await _getFilePath(key);
    final file = File(path);
    await file.writeAsString(value.toString());
  }

  static Future<bool> getBool(String key, bool defaultValue) async {
    final path = await _getFilePath(key);
    final file = File(path);
    if (!file.existsSync()) {
      return defaultValue;
    }
    final content = await file.readAsString();
    return content.toLowerCase() == 'true' ? true : defaultValue;
  }

  static Future<void> remove(String key) async {
    final path = await _getFilePath(key);
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
