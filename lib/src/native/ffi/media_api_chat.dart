// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class MediaApiChatBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  MediaApiChatBinding(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  MediaApiChatBinding.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  RAPID_MediaChat RAPID_MediaChat_Create() {
    return _RAPID_MediaChat_Create();
  }

  late final _RAPID_MediaChat_CreatePtr =
      _lookup<ffi.NativeFunction<RAPID_MediaChat Function()>>(
        'RAPID_MediaChat_Create',
      );
  late final _RAPID_MediaChat_Create =
      _RAPID_MediaChat_CreatePtr.asFunction<RAPID_MediaChat Function()>();

  void RAPID_MediaChat_SetAudioSampleRate(
    RAPID_MediaChat chat,
    int sample_rate,
  ) {
    return _RAPID_MediaChat_SetAudioSampleRate(chat, sample_rate);
  }

  late final _RAPID_MediaChat_SetAudioSampleRatePtr =
      _lookup<
        ffi.NativeFunction<ffi.Void Function(RAPID_MediaChat, ffi.Int32)>
      >('RAPID_MediaChat_SetAudioSampleRate');
  late final _RAPID_MediaChat_SetAudioSampleRate =
      _RAPID_MediaChat_SetAudioSampleRatePtr.asFunction<
        void Function(RAPID_MediaChat, int)
      >();

  int RAPID_MediaChat_IsStarted(RAPID_MediaChat chat) {
    return _RAPID_MediaChat_IsStarted(chat);
  }

  late final _RAPID_MediaChat_IsStartedPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaChat)>>(
        'RAPID_MediaChat_IsStarted',
      );
  late final _RAPID_MediaChat_IsStarted =
      _RAPID_MediaChat_IsStartedPtr.asFunction<int Function(RAPID_MediaChat)>();

  void RAPID_MediaChat_Start(RAPID_MediaChat chat) {
    return _RAPID_MediaChat_Start(chat);
  }

  late final _RAPID_MediaChat_StartPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaChat)>>(
        'RAPID_MediaChat_Start',
      );
  late final _RAPID_MediaChat_Start =
      _RAPID_MediaChat_StartPtr.asFunction<void Function(RAPID_MediaChat)>();

  void RAPID_MediaChat_Stop(RAPID_MediaChat chat) {
    return _RAPID_MediaChat_Stop(chat);
  }

  late final _RAPID_MediaChat_StopPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaChat)>>(
        'RAPID_MediaChat_Stop',
      );
  late final _RAPID_MediaChat_Stop =
      _RAPID_MediaChat_StopPtr.asFunction<void Function(RAPID_MediaChat)>();

  int RAPID_MediaChat_StartDump(RAPID_MediaChat chat) {
    return _RAPID_MediaChat_StartDump(chat);
  }

  late final _RAPID_MediaChat_StartDumpPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaChat)>>(
        'RAPID_MediaChat_StartDump',
      );
  late final _RAPID_MediaChat_StartDump =
      _RAPID_MediaChat_StartDumpPtr.asFunction<int Function(RAPID_MediaChat)>();

  int RAPID_MediaChat_StopDump(RAPID_MediaChat chat) {
    return _RAPID_MediaChat_StopDump(chat);
  }

  late final _RAPID_MediaChat_StopDumpPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaChat)>>(
        'RAPID_MediaChat_StopDump',
      );
  late final _RAPID_MediaChat_StopDump =
      _RAPID_MediaChat_StopDumpPtr.asFunction<int Function(RAPID_MediaChat)>();

  void RAPID_MediaChat_Release(RAPID_MediaChat chat) {
    return _RAPID_MediaChat_Release(chat);
  }

  late final _RAPID_MediaChat_ReleasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaChat)>>(
        'RAPID_MediaChat_Release',
      );
  late final _RAPID_MediaChat_Release =
      _RAPID_MediaChat_ReleasePtr.asFunction<void Function(RAPID_MediaChat)>();

  void RAPID_MediaChat_SetAin(
    RAPID_MediaChat chat,
    RAPID_SDL_Ain_Opaque_Ptr ain,
  ) {
    return _RAPID_MediaChat_SetAin(chat, ain);
  }

  late final _RAPID_MediaChat_SetAinPtr =
      _lookup<
        ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaChat, RAPID_SDL_Ain_Opaque_Ptr)
        >
      >('RAPID_MediaChat_SetAin');
  late final _RAPID_MediaChat_SetAin =
      _RAPID_MediaChat_SetAinPtr.asFunction<
        void Function(RAPID_MediaChat, RAPID_SDL_Ain_Opaque_Ptr)
      >();

  void RAPID_MediaChat_SetChatChannel(
    RAPID_MediaChat chat,
    RAPID_Core_ChatChannel_Opaque_Ptr channel,
  ) {
    return _RAPID_MediaChat_SetChatChannel(chat, channel);
  }

  late final _RAPID_MediaChat_SetChatChannelPtr =
      _lookup<
        ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaChat, RAPID_Core_ChatChannel_Opaque_Ptr)
        >
      >('RAPID_MediaChat_SetChatChannel');
  late final _RAPID_MediaChat_SetChatChannel =
      _RAPID_MediaChat_SetChatChannelPtr.asFunction<
        void Function(RAPID_MediaChat, RAPID_Core_ChatChannel_Opaque_Ptr)
      >();

  void RAPID_MediaChat_ConfigureAudioProcessing(
    RAPID_MediaChat chat,
    int ns_level,
    int aec_mode,
    int agc_profile,
  ) {
    return _RAPID_MediaChat_ConfigureAudioProcessing(
      chat,
      ns_level,
      aec_mode,
      agc_profile,
    );
  }

  late final _RAPID_MediaChat_ConfigureAudioProcessingPtr =
      _lookup<
        ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaChat, ffi.Int32, ffi.Int32, ffi.Int32)
        >
      >('RAPID_MediaChat_ConfigureAudioProcessing');
  late final _RAPID_MediaChat_ConfigureAudioProcessing =
      _RAPID_MediaChat_ConfigureAudioProcessingPtr.asFunction<
        void Function(RAPID_MediaChat, int, int, int)
      >();
}

abstract class RAPID_MediaChatAudioSampleRate {
  static const int RAPID_MEDIA_CHAT_AUDIO_SAMPLE_RATE_8K = 0;
  static const int RAPID_MEDIA_CHAT_AUDIO_SAMPLE_RATE_16K = 1;
}

typedef RAPID_MediaChat = ffi.Pointer<ffi.Void>;
typedef RAPID_SDL_Ain_Opaque_Ptr = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_ChatChannel_Opaque_Ptr = ffi.Pointer<ffi.Void>;
