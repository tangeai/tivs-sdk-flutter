import 'package:flutter/services.dart';

void setFullScreenOrientation(bool isFullScreen) {
  if (isFullScreen) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}

void setFullScreenSystemUI(bool isFullScreen) {
  if (isFullScreen) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}