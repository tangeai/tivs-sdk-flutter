import 'package:flutter/foundation.dart' show internal, kDebugMode;

final Expando<void Function(bool)> _videoFrameDumpControls =
    Expando<void Function(bool)>('videoFrameDumpControls');

@internal
void registerVideoFrameDumpControl(
  Object player,
  void Function(bool) control,
) {
  if (!kDebugMode) return;
  _videoFrameDumpControls[player] = control;
}

@internal
void unregisterVideoFrameDumpControl(Object player) {
  if (!kDebugMode) return;
  _videoFrameDumpControls[player] = null;
}

@internal
void setVideoFrameDumpEnabled(Object player, bool enable) {
  if (!kDebugMode) {
    throw UnsupportedError('Video frame diagnostics require a Debug build');
  }
  final control = _videoFrameDumpControls[player];
  if (control == null) {
    throw StateError('Player is unavailable for video frame diagnostics');
  }
  control(enable);
}
