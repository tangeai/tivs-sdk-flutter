part of 'library.dart';

enum Environment { release, pre, test }

class RapidKit {
  static const String _defaultLanguage = "zh-cn";
  static const String _tag = "RapidKit";
  static const int _nativeCoreSuccess = 1;

  RapidKit._();

  static String get versionName => rapidNativeCoreVersionName();

  static String get buildId => rapidNativeCoreBuildId();

  static String get commitHash => rapidNativeCoreCommitHash();

  static Future<bool> initialize(Configurations configurations) async {
    _checkDartVersionDeprecation();

    String loggingCacheDirectory = await _PlatformChannel.requireLoggingCacheDirectory();
    if (loggingCacheDirectory.isEmpty) {
      throw Exception("platform channel implementation missing: logging cache directory is required");
    }

    final internalConfigurations = ConfigurationsInternal(
        id: configurations.id,
        package: configurations.package,
        language: configurations.language,
        debugging: configurations.debugging,
        environment: configurations.environment,
        httpLogging: configurations.httpLogging,
        loggingCacheDirectory: loggingCacheDirectory);

    rapidDartBinding();

    final initResult = await initializeInternal(internalConfigurations);
    final isSuccess = initResult == _nativeCoreSuccess;
    if (isSuccess) PersistentChannel.disconnect(); // force disconnect the persistent channel

    return isSuccess;
  }

  static void _checkDartVersionDeprecation() {
    final dartVersion = Platform.version;
    final versionMatch = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(dartVersion);

    if (versionMatch != null) {
      final majorVersion = int.parse(versionMatch.group(1)!);

      if (majorVersion < 3) {
        debugPrint("[$_tag] ===========================================================");
        debugPrint("[$_tag]  注意 >>> rapid_kit 将从 v1.1.0 开始，移除对 Dart 2 的支持！");
        debugPrint("[$_tag]  ");
        debugPrint("[$_tag]  当前本地的 Dart 版本: ${versionMatch.group(0)}， 届时你将无法使用新版本 rapid_kit。");
        debugPrint("[$_tag]  建议 >>> 尽快升级 Flutter SDK, 最低要求：");
        debugPrint("[$_tag]    1. 针对 HarmonyOS_NEXT 社区版 Flutter: 采用 3.22.1 或更高版本");
        debugPrint("[$_tag]    2. 针对 Google 标准版 Flutter: 采用 3.32.2 或更高版本");
        debugPrint("[$_tag] ===========================================================");
      }
    }
  }

  static Future<int> initializeInternal(ConfigurationsInternal configurations) => compute(_initialize, configurations);

  static int _initialize(ConfigurationsInternal configurations) => rapidNativeCoreInitialize(
      configurations.id,
      configurations.package,
      configurations.language ?? _defaultLanguage,
      configurations.debugging ?? false,
      configurations.environment?.index ?? 0,
      configurations.httpLogging,
      configurations.loggingCacheDirectory);
}

// define a ConfigurationsInternal class that extends Configurations, with a new property: loggingCacheDirectory and consoleLogging
class ConfigurationsInternal extends Configurations {
  ConfigurationsInternal(
      {required super.id,
      required super.package,
      super.language,
      super.debugging,
      super.environment,
      super.httpLogging,
      required this.loggingCacheDirectory});
  final String loggingCacheDirectory;
}
