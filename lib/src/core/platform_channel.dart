part of 'library.dart';

MethodChannel _channel = const MethodChannel(
  'com.tange.ai/rapid_kit/method.channel',
);

class _PlatformChannel {
  static Future<int> attachPlayerTexture(
    int playerPtr,
    int containerWidth,
    int containerHeight, {
    int? playerOutputToken,
  }) async {
    final int? result =
        await _channel.invokeMethod<int>('attachPlayerTexture', {
      "playerPtr": playerPtr,
      if (playerOutputToken != null) "playerOutputToken": playerOutputToken,
      "containerWidth": containerWidth,
      "containerHeight": containerHeight,
    });
    return result ?? (throw Exception('Expected int but got null'));
  }

  static Future<void> detachPlayerTexture(int textureId) async {
    await _channel.invokeMethod<void>('detachPlayerTexture', {
      "textureId": textureId,
    });
  }

  static Future<int> ensurePlayerTexture(
    int playerPtr,
    int currentTextureId,
    int containerWidth,
    int containerHeight, {
    required bool forceRecreate,
  }) async {
    final int? result = await _channel.invokeMethod<int>(
      'ensurePlayerTexture',
      {
        "playerPtr": playerPtr,
        "currentTextureId": currentTextureId,
        "containerWidth": containerWidth,
        "containerHeight": containerHeight,
        "forceRecreate": forceRecreate,
      },
    );
    return result ?? (throw Exception('Expected int but got null'));
  }

  static Future<void> updatePlayerTextureSize(
    int textureId,
    int containerWidth,
    int containerHeight,
  ) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('updatePlayerTextureSize', {
      "textureId": textureId,
      "containerWidth": containerWidth,
      "containerHeight": containerHeight,
    });
  }

  static Future<void> setAndroidGlesVideoRender(bool enable) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setAndroidGlesVideoRender', {
      "enable": enable,
    });
  }

  static Future<bool> attachMediaChat(
    int chatPtr, {
    bool hardwareAec = false,
    bool hardwareNs = false,
    bool hardwareAgc = false,
    bool iosVoiceProcessing = false,
    int? playbackPlayerPtr,
  }) async {
    final arguments = <String, Object>{
      "mediaChatPtr": chatPtr,
      "hardwareAec": hardwareAec,
      "hardwareNs": hardwareNs,
      "hardwareAgc": hardwareAgc,
      if (Platform.isIOS) "iosVoiceProcessing": iosVoiceProcessing,
      if (Platform.isIOS && playbackPlayerPtr != null)
        "playbackPlayerPtr": playbackPlayerPtr,
    };
    final bool? result =
        await _channel.invokeMethod<bool>('attachMediaChat', arguments);
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<bool> setAndroidPlayerVoiceCommunication(
    int playerPtr,
    bool enable,
    int playerOutputToken,
  ) async {
    if (!Platform.isAndroid) return true;
    final bool? result = await _channel.invokeMethod<bool>(
      'setAndroidPlayerVoiceCommunication',
      {"playerPtr": playerPtr, "playerOutputToken": playerOutputToken, "enable": enable},
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<bool> setIosVoiceProcessing(int chatPtr, bool enable) async {
    if (!Platform.isIOS) return true;
    final bool? result =
        await _channel.invokeMethod<bool>('setIosVoiceProcessing', {
      "mediaChatPtr": chatPtr,
      "enable": enable,
    });
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<String> requireWriteableCachePath() async {
    if (Platform.isWindows) return directoryOnWindows('cache');

    final String? result = await _channel.invokeMethod<String>(
      'requireWriteableCachePath',
    );
    return result ?? (throw Exception('Expected String but got null'));
  }

  static Future<String> requireLoggingCacheDirectory() async {
    if (Platform.isWindows) return directoryOnWindows('log');

    final String? result = await _channel.invokeMethod<String>(
      'requireLoggingCacheDirectory',
    );
    return result ?? (throw Exception('Expected String but got null'));
  }

  static Future<bool> exportCapturedVideo(
    String cachePath, {
    String? galleryName,
  }) async {
    if (Platform.isWindows) return _copyToDesktopOnWindows(cachePath);
    if (Platform.isLinux) {
      return _copyToUserDirectoryOnLinux(cachePath, 'Videos');
    }

    final Map<String, dynamic> arguments = {"cachePath": cachePath};
    if (galleryName != null) {
      arguments["galleryName"] = galleryName;
    }

    final bool? result = await _channel.invokeMethod<bool>(
      'exportCapturedVideo',
      arguments,
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<int> requireMicrophone() async {
    final int? result = await _channel.invokeMethod<int>('requireMicrophone');
    return result ?? (throw Exception('Expected int but got null'));
  }

  /// Copy the file to the desktop on Windows.
  /// and named it as time-related, like 2025-01-01-11-11-11.mp4
  static Future<bool> _copyToDesktopOnWindows(String cachePath) async {
    if (!Platform.isWindows) return false;
    try {
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final extension = path.basename(cachePath).split('.').last;
      final desktopPath = path.join(
        Platform.environment['USERPROFILE']!,
        'Desktop',
      );
      final finalPath = path.join(desktopPath, '$timestamp.$extension');
      await File(cachePath).copy(finalPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _copyToUserDirectoryOnLinux(
    String cachePath,
    String directoryName,
  ) async {
    if (!Platform.isLinux) return false;
    try {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return false;
      final directory = Directory(path.join(home, directoryName));
      await directory.create(recursive: true);
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final extension = path.extension(cachePath);
      await File(cachePath).copy(
        path.join(directory.path, 'rapid-$timestamp$extension'),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> exportCapturedPicture(String cachePath) async {
    if (Platform.isWindows) return _copyToDesktopOnWindows(cachePath);
    if (Platform.isLinux) {
      return _copyToUserDirectoryOnLinux(cachePath, 'Pictures');
    }
    final bool? result = await _channel.invokeMethod<bool>(
      'exportCapturedPicture',
      {"cachePath": cachePath},
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<bool> isMicrophoneRequired() async {
    final bool? result = await _channel.invokeMethod<bool>(
      'isMicrophoneRequired',
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<bool> isFileAccessPermissionGranted() async {
    if (Platform.isWindows || Platform.isLinux) return true;
    final bool? result = await _channel.invokeMethod<bool>(
      'isFileAccessPermissionGranted',
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<int> requestFileAccessPermission() async {
    final int? result = await _channel.invokeMethod<int>(
      'requestFileAccessPermission',
    );
    return result ?? (throw Exception('Expected int but got null'));
  }

  static Future<void> createAudioSession() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('createAudioSession');
  }

  static Future<String> localNetworkBroadcastAddress(
      {bool logDetails = true}) async {
    final String? result = await _channel.invokeMethod<String>(
      'localNetworkBroadcastAddress',
      {'logDetails': logDetails},
    );
    return result ?? (throw Exception('Expected String but got null'));
  }

  static Future<void> destroyAudioSession() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod<void>('destroyAudioSession');
    }
  }

  static Future<String> accountRobotCheck() async {
    final String? result = await _channel.invokeMethod<String>(
      'accountRobotCheck',
    );
    return result ?? (throw Exception('Expected String but got null'));
  }

  static Future<String> currentWifi() async {
    final String? result = await _channel.invokeMethod<String>('currentWifi');
    return result ?? (throw Exception('Expected String but got null'));
  }

  static Future<int> requireLocationPermission() async {
    final int? result = await _channel.invokeMethod<int>(
      'requireLocationPermission',
    );
    return result ?? (throw Exception('Expected int but got null'));
  }

  static Future<bool> ensureTransportByWifi() async {
    if (!Platform.isAndroid) return true;
    final bool? result = await _channel.invokeMethod<bool>(
      'ensureTransportByWifi',
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<bool> releaseTransportWiFi() async {
    if (!Platform.isAndroid) return true;
    final bool? result = await _channel.invokeMethod<bool>(
      'releaseTransportWiFi',
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<String> directoryOnWindows(String name) async {
    if (!Platform.isWindows) {
      return '';
    }

    final appData = Platform.environment['USERPROFILE'];
    if (appData != null) {
      return '$appData\\.RapitKitExample\\$name';
    } else {
      return '';
    }
  }

  static Future<bool> isLocationPermissionRequired() async =>
      await _channel.invokeMethod<bool>('isLocationPermissionRequired') ??
      (throw Exception('null'));

  static Future<bool> launchWiFiSettings() async {
    final bool? result = await _channel.invokeMethod<bool>(
      'launchWiFiSettings',
    );
    return result ?? (throw Exception('Expected bool but got null'));
  }

  static Future<int> acquireBluetoothPermission() async {
    final int? result = await _channel.invokeMethod<int>(
      'acquireBluetoothPermission',
    );
    return result ?? (throw Exception('Expected int but got null'));
  }

  static Future<bool> isBluetoothPermissionGranted() async =>
      await _channel.invokeMethod<bool>('isBluetoothPermissionGranted') ??
      (throw Exception('null'));
  static Future<bool> isBluetoothEnabled() async =>
      await _channel.invokeMethod<bool>('isBluetoothEnabled') ??
      (throw Exception('null'));
  static Future<void> startBluetoothDiscovery() async =>
      await _channel.invokeMethod<void>('startBluetoothDiscovery');
  static Future<void> stopBluetoothDiscovery() async =>
      await _channel.invokeMethod<void>('stopBluetoothDiscovery');
  static Future<List<Map<String, String>>> getBluetoothDevices() async {
    final List<dynamic> devices = (await _channel.invokeMethod<List<dynamic>>(
      'getBluetoothDevices',
    ))!;
    return devices
        .map(
          (dynamic device) =>
              Map<String, String>.from(device as Map<dynamic, dynamic>),
        )
        .toList();
  }

  static Future<bool> connectBluetoothDevice(
    String mac,
    List<String>? characteristics,
  ) async =>
      await _channel.invokeMethod<bool>('connectBluetoothDevice', {
        "mac": mac,
        "characteristics": characteristics,
      }) ??
      (throw Exception('null'));
  static Future<void> disconnectBluetoothDevice(String mac) async =>
      await _channel.invokeMethod<void>('disconnectBluetoothDevice', {
        "mac": mac,
      });
  static Future<bool> writeBluetoothData(Uint8List data) async =>
      await _channel.invokeMethod<bool>('writeBluetoothData', data) ??
      (throw Exception('null'));
}
