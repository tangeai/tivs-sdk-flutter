part of '../rapid_kit_sample_pages.dart';

class RapidInitialize {
  RapidInitialize._();

  static Future<bool> init() async {
    String appId = "";
    String packageName = "";
    int apiEnv = 0;

    String? localAppId = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyAppConfigAppId);
    String? localPackageName = await SharedPreferencesUtil.instance
        .getString(SampleConstants.storageKeyAppConfigPackageName);
    int? localApiEnv = await SharedPreferencesUtil.instance
        .getInt(SampleConstants.storageKeyAppConfigApiEnv);

    if (localAppId?.isNotEmpty == true) {
      appId = localAppId!;
    } else {
      appId = SampleConstants.defaultRapidAppID;
    }

    if (localPackageName?.isNotEmpty == true) {
      packageName = localPackageName!;
    } else {
      packageName = SampleConstants.defaultRapidPackageName;
    }

    if (localApiEnv != null) {
      apiEnv = localApiEnv;
    }

    int localRuntimeLoggingEnableValue = (await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigRuntimeLogging) ??
        SampleConstants.switchOffValue);
    bool runtimeLoggingEnable =
        localRuntimeLoggingEnableValue == SampleConstants.switchOnValue;

    int httpLoggingEnableValue = (await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigHttpLogging) ??
        SampleConstants.switchOffValue);

    bool httpLoggingEnable =
        httpLoggingEnableValue == SampleConstants.switchOnValue;

    int intercom16kSamplingEnableValue = (await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigIntercom16kSampling) ??
        SampleConstants.switchOffValue);
    SampleConstants.intercom16kSamplingEnabled =
        intercom16kSamplingEnableValue == SampleConstants.switchOnValue;

    int tgrtcTcpModeEnableValue = (await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigTgrtcTcpMode) ??
        SampleConstants.switchOffValue);
    SampleConstants.tgrtcTcpModeEnabled =
        tgrtcTcpModeEnableValue == SampleConstants.switchOnValue;

    int pureAudioModeEnableValue = (await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigPureAudioMode) ??
        SampleConstants.switchOffValue);
    SampleConstants.pureAudioModeEnabled =
        pureAudioModeEnableValue == SampleConstants.switchOnValue;

    bool bufferingModeConfigured = await SharedPreferencesUtil.instance.getBool(
            SampleConstants.storageKeyAppConfigBufferingModeConfigured) ??
        false;
    int bufferingMode = bufferingModeConfigured
        ? await SharedPreferencesUtil.instance
                .getInt(SampleConstants.storageKeyAppConfigBufferingMode) ??
            SampleConstants.bufferingMode
        : SampleConstants.bufferingMode;
    if (bufferingMode < 0 ||
        bufferingMode >= PlayerBufferingMode.values.length) {
      bufferingMode = SampleConstants.bufferingMode;
    }
    int fixedBufferingMs = await SharedPreferencesUtil.instance
            .getInt(SampleConstants.storageKeyAppConfigFixedBufferingMs) ??
        SampleConstants.fixedBufferingMs;
    if (fixedBufferingMs <= 0) {
      fixedBufferingMs = SampleConstants.fixedBufferingMs;
    }
    SampleConstants.bufferingMode = bufferingMode;
    SampleConstants.fixedBufferingMs = fixedBufferingMs;
    Player.setDefaultBufferingMode(PlayerBufferingMode.values[bufferingMode],
        bufferingMs: fixedBufferingMs);

    bool clockModeConfigured = await SharedPreferencesUtil.instance
            .getBool(SampleConstants.storageKeyAppConfigClockModeConfigured) ??
        false;
    int clockMode = clockModeConfigured
        ? await SharedPreferencesUtil.instance
                .getInt(SampleConstants.storageKeyAppConfigClockMode) ??
            SampleConstants.clockMode
        : SampleConstants.clockMode;
    if (clockMode < 0 || clockMode >= PlayerClockMode.values.length) {
      clockMode = SampleConstants.clockMode;
    }
    SampleConstants.clockMode = clockMode;
    Player.setDefaultClockMode(PlayerClockMode.values[clockMode]);

    int videoDecoderPreference = await SharedPreferencesUtil.instance.getInt(
            SampleConstants.storageKeyAppConfigVideoDecoderPreference) ??
        SampleConstants.videoDecoderPreference;
    videoDecoderPreference =
        SampleConstants.resolveVideoDecoderPreference(videoDecoderPreference);
    SampleConstants.applyVideoDecoderPreference(videoDecoderPreference);

    final initialized = await RapidKit.initialize(Configurations(
        id: appId,
        package: packageName,
        httpLogging: httpLoggingEnable,
        debugging: runtimeLoggingEnable,
        environment: Environment.values[apiEnv]));

    if (initialized) await WifiAbility.set_network_logging_enabled(true);
    return initialized;
  }
}
