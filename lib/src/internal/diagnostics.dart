import '../core/library.dart';
import '../native/library.dart';
import 'player_diagnostics_bridge.dart';

class RapidDiagnostics {
  static void enableStreamDebugging(bool enable) =>
      RapidNativeStreamDiagnostics.enableDebugging(enable);

  static void enableVideoFrameDump(Player player, bool enable) =>
      setVideoFrameDumpEnabled(player, enable);
}
