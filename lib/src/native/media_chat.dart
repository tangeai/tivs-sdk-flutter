part of 'library.dart';

class RapidNativeMediaChat {
  Pointer<Void>? _ptr;

  bool create() {
    _ptr = mediaApiChatBinding.RAPID_MediaChat_Create();
    return _ptr != nullptr;
  }

  void setChannel(RapidNativeChatChannel nativeChatChannel) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiChatBinding.RAPID_MediaChat_SetChatChannel(
        _ptr!,
        nativeChatChannel._ptr!,
      );
    }
  }

  void setAudioSampleRate(int sampleRate) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiChatBinding.RAPID_MediaChat_SetAudioSampleRate(_ptr!, sampleRate);
    }
  }

  void configureAudioProcessing(int nsLevel, int aecLevel, int agcLevel) {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiChatBinding.RAPID_MediaChat_ConfigureAudioProcessing(
        _ptr!,
        nsLevel,
        aecLevel,
        agcLevel,
      );
    }
  }

  void start() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiChatBinding.RAPID_MediaChat_Start(_ptr!);
    }
  }

  bool started() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiChatBinding.RAPID_MediaChat_IsStarted(_ptr!) == 1;
    }
    return false;
  }

  void stop() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiChatBinding.RAPID_MediaChat_Stop(_ptr!);
    }
  }

  bool startDump() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiChatBinding.RAPID_MediaChat_StartDump(_ptr!) == 0;
    }
    return false;
  }

  bool stopDump() {
    if (_ptr != null && _ptr != nullptr) {
      return mediaApiChatBinding.RAPID_MediaChat_StopDump(_ptr!) == 0;
    }
    return false;
  }

  void destroy() {
    if (_ptr != null && _ptr != nullptr) {
      mediaApiChatBinding.RAPID_MediaChat_Release(_ptr!);
      _ptr = null;
    }
  }

  int get ptr => _ptr != null ? _ptr!.address : 0;
}
