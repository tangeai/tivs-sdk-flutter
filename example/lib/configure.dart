import 'package:rapid_kit/rapid_kit.dart';

class RapidSampleConfigure {
  static const String rapidLanguage = "zh-cn";
  static const bool rapidDebuggingMode = true;
  static const Environment rapidEnvironment = Environment.release;

  static const String protocolUrl = "https://api-cn01.tange365.com/app/protocol/detail.html";
  static const String privacyUrl = "https://api-cn01.tange365.com/app/privacy/detail.html";

  static const VideoDecoderPreference videoDecoderPreferenceDefault = VideoDecoderPreference.auto;
  static const bool homePreconnectPipeEnabledDefault = false;
}
