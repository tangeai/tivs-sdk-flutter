part of 'rapid_kit_sample_configure.dart';

class SampleConstants {
  static const String defaultRapidAppID = String.fromEnvironment('RAPID_APP_ID');
  static const String defaultRapidPackageName =
      String.fromEnvironment('RAPID_PACKAGE_NAME');
  static const String productionRapidAppID = "5920020";
  static const String productionRapidPackageName = "com.tange365.icam365";
  static const String storageKeyAppConfigAppId = "rapid_sample_app_id";
  static const String storageKeyAppConfigPackageName =
      "rapid_sample_package_name";
  static const String storageKeyAppConfigApiEnv = "rapid_sample_api_env";
  static const String storageKeyAppConfigRuntimeLogging =
      "rapid_sample_runtime_logging";
  static const String storageKeyAppConfigHttpLogging =
      "rapid_sample_http_logging";
  static const String storageKeyAppConfigIntercom16kSampling =
      "rapid_sample_intercom_16k_sampling";
  static const String storageKeyLoginAccount = "rapid_sample_account";
  static const String storageKeyLoginToken = "rapid_sample_user_access_token";
  static const String storageKeyLoginDebuggingCode =
      "rapid_sample_login_debugging_code";
  static const String storageKeyWifiSSID = "rapid_sample_wifi_ssid";
  static const String storageKeyWifiPassword = "rapid_sample_wifi_password";
  static const String storageKeyInstructionId = "rapid_sample_instruction_id";
  static const String storageKeyInstructionData =
      "rapid_sample_instruction_data";
  static const String storageKeyAgreementPrivacyStatus =
      "rapid_sample_agreement_status_privacy";
  static const String storageKeyAgreementTermsStatus =
      "rapid_sample_agreement_status_terms";
  static const String storageKeyAppConfigTgrtcDebugging =
      "rapid_sample_tgrtc_debugging";
  static const String storageKeyAppConfigStreamDebugging =
      "rapid_sample_stream_debugging";
  static const String storageKeyAppConfigTgrtcTcpMode =
      "rapid_sample_tgrtc_tcp_mode";
  static const String storageKeyAppConfigPureAudioMode =
      "rapid_sample_pure_audio_mode";
  static const String storageKeyAppConfigBufferingMode =
      "rapid_sample_buffering_mode";
  static const String storageKeyAppConfigBufferingModeConfigured =
      "rapid_sample_buffering_mode_configured";
  static const String storageKeyAppConfigFixedBufferingMs =
      "rapid_sample_fixed_buffering_ms";
  static const String storageKeyAppConfigClockMode = "rapid_sample_clock_mode";
  static const String storageKeyAppConfigClockModeConfigured =
      "rapid_sample_clock_mode_configured";
  static const String storageKeyAppConfigVideoDecoderPreference =
      "rapid_sample_video_decoder_preference";
  static const String storageKeyLiveStreamQuality =
      "rapid_sample_live_stream_quality";

  static const String storageKeyAudioPlaybackNsLevel =
      'rapid_sample_audio_playback_ns_level';
  static const String storageKeyAudioPlaybackNsArtifactFixApplied =
      'rapid_sample_audio_playback_ns_artifact_fix_applied';
  static const String storageKeyAudioPlaybackAgcLevel =
      'rapid_sample_audio_playback_agc_profile';
  static const String storageKeyAudioFeedbackLoopFixApplied =
      'rapid_sample_audio_feedback_loop_fix_applied';
  static const String storageKeyAudioIntercomAecLevel =
      'rapid_sample_audio_intercom_aec';
  static const String storageKeyAudioIntercomNsLevel =
      'rapid_sample_audio_intercom_ns_level';
  static const String storageKeyAudioIntercomAgcLevel =
      'rapid_sample_audio_intercom_agc_profile';

  static bool intercom16kSamplingEnabled = false;
  static bool tgrtcTcpModeEnabled = false;
  static bool pureAudioModeEnabled = false;
  static int bufferingMode = 1;
  static int fixedBufferingMs = 200;
  static int clockMode = 0;
  static int videoDecoderPreference =
      RapidSampleConfigure.videoDecoderPreferenceDefault.index;
  static int? _runtimeVideoDecoderPreferenceOverride;

  static bool intercomAecEnabled = false;
  static int defaultAudioIntercomAecLevel = 0;
  static const int defaultAudioPlaybackAgcLevel = 0;
  static const int defaultAudioIntercomNsLevel = 0;
  static const int defaultAudioIntercomAgcLevel = 2;

  static const int switchOffValue = 0;
  static const int switchOnValue = 1;

  static int normalizeVideoDecoderPreference(int preference) {
    if (preference < 0 || preference >= VideoDecoderPreference.values.length) {
      return RapidSampleConfigure.videoDecoderPreferenceDefault.index;
    }
    return preference;
  }

  static void setRuntimeVideoDecoderPreferenceOverride(
      VideoDecoderPreference? preference) {
    _runtimeVideoDecoderPreferenceOverride = preference?.index;
    if (preference != null) {
      applyVideoDecoderPreference(preference.index);
    }
  }

  static int resolveVideoDecoderPreference(int preference) {
    return _runtimeVideoDecoderPreferenceOverride ??
        normalizeVideoDecoderPreference(preference);
  }

  static void applyVideoDecoderPreference(int preference) {
    final activePreference = resolveVideoDecoderPreference(preference);
    videoDecoderPreference = activePreference;
    Player.setDefaultVideoDecoderPreference(
        VideoDecoderPreference.values[activePreference]);
  }
}
