part of 'library.dart';

class RapidNativeChatChannel {
  final RapidNativePipe _nativePipe;

  RapidNativeChatChannel(RapidNativePipe pipe) : _nativePipe = pipe;
  Pointer<Void>? _ptr;

  bool create() {
    if (_nativePipe._pipePtr != null && _nativePipe._pipePtr != nullptr) {
      _ptr = coreApiChatBinding.RAPID_Core_ChatChannel_Create(_nativePipe._pipePtr!);
      return _ptr != nullptr;
    } else {
      return false;
    }
  }

  void setAudioSampleRate(int sampleRate) {
    if (_ptr != null && _ptr != nullptr) {
      coreApiChatBinding.RAPID_Core_ChatChannel_SetAudioSampleRate(_ptr!, sampleRate);
    }
  }

  void destroy() {
    if (_ptr != null && _ptr != nullptr) {
      coreApiChatBinding.RAPID_Core_ChatChannel_Free(_ptr!);
      _ptr = null;
    }
  }
}
