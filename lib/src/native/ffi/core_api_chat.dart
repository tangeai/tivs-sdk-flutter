// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiChatBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiChatBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiChatBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  RAPID_Core_ChatChannel RAPID_Core_ChatChannel_Create(
    ffi.Pointer<ffi.Void> pipe_proxy,
  ) {
    return _RAPID_Core_ChatChannel_Create(
      pipe_proxy,
    );
  }

  late final _RAPID_Core_ChatChannel_CreatePtr =
      _lookup<ffi.NativeFunction<RAPID_Core_ChatChannel Function(ffi.Pointer<ffi.Void>)>>('RAPID_Core_ChatChannel_Create');
  late final _RAPID_Core_ChatChannel_Create = _RAPID_Core_ChatChannel_CreatePtr.asFunction<RAPID_Core_ChatChannel Function(ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_ChatChannel_SetAudioSampleRate(
    RAPID_Core_ChatChannel channel,
    int sample_rate,
  ) {
    return _RAPID_Core_ChatChannel_SetAudioSampleRate(
      channel,
      sample_rate,
    );
  }

  late final _RAPID_Core_ChatChannel_SetAudioSampleRatePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ChatChannel, ffi.Int32)>>('RAPID_Core_ChatChannel_SetAudioSampleRate');
  late final _RAPID_Core_ChatChannel_SetAudioSampleRate =
      _RAPID_Core_ChatChannel_SetAudioSampleRatePtr.asFunction<void Function(RAPID_Core_ChatChannel, int)>();

  void RAPID_Core_ChatChannel_Free(
    RAPID_Core_ChatChannel channel,
  ) {
    return _RAPID_Core_ChatChannel_Free(
      channel,
    );
  }

  late final _RAPID_Core_ChatChannel_FreePtr = _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_ChatChannel)>>('RAPID_Core_ChatChannel_Free');
  late final _RAPID_Core_ChatChannel_Free = _RAPID_Core_ChatChannel_FreePtr.asFunction<void Function(RAPID_Core_ChatChannel)>();
}

abstract class RAPID_Core_ChatAudioSampleRate {
  static const int RAPID_CORE_CHAT_AUDIO_SAMPLE_RATE_8K = 0;
  static const int RAPID_CORE_CHAT_AUDIO_SAMPLE_RATE_16K = 1;
}

typedef RAPID_Core_ChatChannel = ffi.Pointer<ffi.Void>;
