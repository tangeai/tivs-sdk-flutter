// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class MediaApiPlayerBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  MediaApiPlayerBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  MediaApiPlayerBinding.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ffi.Pointer<T>? _lookupOptional<T extends ffi.NativeType>(
      String symbolName) {
    try {
      return _lookup<T>(symbolName);
    } on ArgumentError {
      return null;
    }
  }

  RAPID_MediaPlayer RAPID_MediaPlayer_Create() {
    return _RAPID_MediaPlayer_Create();
  }

  late final _RAPID_MediaPlayer_CreatePtr =
      _lookup<ffi.NativeFunction<RAPID_MediaPlayer Function()>>(
          'RAPID_MediaPlayer_Create');
  late final _RAPID_MediaPlayer_Create =
      _RAPID_MediaPlayer_CreatePtr.asFunction<RAPID_MediaPlayer Function()>();

  int RAPID_MediaPlayer_GetOutputToken(RAPID_MediaPlayer player) =>
      _RAPID_MediaPlayer_GetOutputToken(player);

  late final _RAPID_MediaPlayer_GetOutputToken = _lookup<
          ffi.NativeFunction<ffi.Int64 Function(RAPID_MediaPlayer)>>(
      'RAPID_MediaPlayer_GetOutputToken')
      .asFunction<int Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Prepare(
    RAPID_MediaPlayer player,
    ffi.Pointer<ffi.Void> provider,
  ) {
    return _RAPID_MediaPlayer_Prepare(
      player,
      provider,
    );
  }

  late final _RAPID_MediaPlayer_PreparePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaPlayer_Prepare');
  late final _RAPID_MediaPlayer_Prepare = _RAPID_MediaPlayer_PreparePtr
      .asFunction<void Function(RAPID_MediaPlayer, ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaPlayer_Mute(
    RAPID_MediaPlayer player,
    int mute,
  ) {
    return _RAPID_MediaPlayer_Mute(
      player,
      mute,
    );
  }

  late final _RAPID_MediaPlayer_MutePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_Mute');
  late final _RAPID_MediaPlayer_Mute = _RAPID_MediaPlayer_MutePtr.asFunction<
      void Function(RAPID_MediaPlayer, int)>();

  int RAPID_MediaPlayer_IsMute(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_IsMute(
      player,
    );
  }

  late final _RAPID_MediaPlayer_IsMutePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_IsMute');
  late final _RAPID_MediaPlayer_IsMute = _RAPID_MediaPlayer_IsMutePtr
      .asFunction<int Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Start(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_Start(
      player,
    );
  }

  late final _RAPID_MediaPlayer_StartPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_Start');
  late final _RAPID_MediaPlayer_Start = _RAPID_MediaPlayer_StartPtr.asFunction<
      void Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Pause(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_Pause(
      player,
    );
  }

  late final _RAPID_MediaPlayer_PausePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_Pause');
  late final _RAPID_MediaPlayer_Pause = _RAPID_MediaPlayer_PausePtr.asFunction<
      void Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Resume(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_Resume(
      player,
    );
  }

  late final _RAPID_MediaPlayer_ResumePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_Resume');
  late final _RAPID_MediaPlayer_Resume = _RAPID_MediaPlayer_ResumePtr
      .asFunction<void Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Stop(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_Stop(
      player,
    );
  }

  late final _RAPID_MediaPlayer_StopPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_Stop');
  late final _RAPID_MediaPlayer_Stop =
      _RAPID_MediaPlayer_StopPtr.asFunction<void Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_State(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_State(
      player,
    );
  }

  late final _RAPID_MediaPlayer_StatePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_State');
  late final _RAPID_MediaPlayer_State =
      _RAPID_MediaPlayer_StatePtr.asFunction<int Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Flush(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_Flush(
      player,
    );
  }

  late final _RAPID_MediaPlayer_FlushPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_Flush');
  late final _RAPID_MediaPlayer_Flush = _RAPID_MediaPlayer_FlushPtr.asFunction<
      void Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_Destroy(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_Destroy(
      player,
    );
  }

  late final _RAPID_MediaPlayer_DestroyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_Destroy');
  late final _RAPID_MediaPlayer_Destroy = _RAPID_MediaPlayer_DestroyPtr
      .asFunction<void Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_BindPlayer(
    RAPID_MediaPlayer player,
    RAPID_MediaPlayer main_target,
  ) {
    return _RAPID_MediaPlayer_BindPlayer(
      player,
      main_target,
    );
  }

  late final _RAPID_MediaPlayer_BindPlayerPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer,
              RAPID_MediaPlayer)>>('RAPID_MediaPlayer_BindPlayer');
  late final _RAPID_MediaPlayer_BindPlayer = _RAPID_MediaPlayer_BindPlayerPtr
      .asFunction<void Function(RAPID_MediaPlayer, RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_SetVout(
    RAPID_MediaPlayer player,
    RAPID_SDL_Vout_Opaque_Ptr vout,
  ) {
    return _RAPID_MediaPlayer_SetVout(
      player,
      vout,
    );
  }

  late final _RAPID_MediaPlayer_SetVoutPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer,
              RAPID_SDL_Vout_Opaque_Ptr)>>('RAPID_MediaPlayer_SetVout');
  late final _RAPID_MediaPlayer_SetVout =
      _RAPID_MediaPlayer_SetVoutPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_SDL_Vout_Opaque_Ptr)>();

  void RAPID_MediaPlayer_SetAout(
    RAPID_MediaPlayer player,
    RAPID_SDL_Aout_Opaque_Ptr aout,
  ) {
    return _RAPID_MediaPlayer_SetAout(
      player,
      aout,
    );
  }

  late final _RAPID_MediaPlayer_SetAoutPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer,
              RAPID_SDL_Aout_Opaque_Ptr)>>('RAPID_MediaPlayer_SetAout');
  late final _RAPID_MediaPlayer_SetAout =
      _RAPID_MediaPlayer_SetAoutPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_SDL_Aout_Opaque_Ptr)>();

  int RAPID_MediaPlayer_Capture(
    RAPID_MediaPlayer player,
    ffi.Pointer<Utf8> path,
  ) {
    return _RAPID_MediaPlayer_Capture(
      player,
      path,
    );
  }

  late final _RAPID_MediaPlayer_CapturePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(RAPID_MediaPlayer,
              ffi.Pointer<Utf8>)>>('RAPID_MediaPlayer_Capture');
  late final _RAPID_MediaPlayer_Capture = _RAPID_MediaPlayer_CapturePtr
      .asFunction<int Function(RAPID_MediaPlayer, ffi.Pointer<Utf8>)>();

  int RAPID_MediaPlayer_StartRecord(
    RAPID_MediaPlayer player,
    ffi.Pointer<Utf8> path,
  ) {
    return _RAPID_MediaPlayer_StartRecord(
      player,
      path,
    );
  }

  late final _RAPID_MediaPlayer_StartRecordPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(RAPID_MediaPlayer,
              ffi.Pointer<Utf8>)>>('RAPID_MediaPlayer_StartRecord');
  late final _RAPID_MediaPlayer_StartRecord = _RAPID_MediaPlayer_StartRecordPtr
      .asFunction<int Function(RAPID_MediaPlayer, ffi.Pointer<Utf8>)>();

  int RAPID_MediaPlayer_StopRecord(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_StopRecord(
      player,
    );
  }

  late final _RAPID_MediaPlayer_StopRecordPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_StopRecord');
  late final _RAPID_MediaPlayer_StopRecord = _RAPID_MediaPlayer_StopRecordPtr
      .asFunction<int Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_GetRecordDurationMs(
    RAPID_MediaPlayer player,
  ) {
    final fn = _RAPID_MediaPlayer_GetRecordDurationMs;
    if (fn == null) return 0;
    return fn(player);
  }

  late final _RAPID_MediaPlayer_GetRecordDurationMsPtr = _lookupOptional<
      ffi.NativeFunction<ffi.LongLong Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_GetRecordDurationMs');
  late final _RAPID_MediaPlayer_GetRecordDurationMs =
      _RAPID_MediaPlayer_GetRecordDurationMsPtr
          ?.asFunction<int Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_StartDump(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_StartDump(
      player,
    );
  }

  late final _RAPID_MediaPlayer_StartDumpPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_StartDump');
  late final _RAPID_MediaPlayer_StartDump = _RAPID_MediaPlayer_StartDumpPtr
      .asFunction<int Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_StopDump(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_StopDump(
      player,
    );
  }

  late final _RAPID_MediaPlayer_StopDumpPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_StopDump');
  late final _RAPID_MediaPlayer_StopDump = _RAPID_MediaPlayer_StopDumpPtr
      .asFunction<int Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_EnableVideoFrameDump(
    RAPID_MediaPlayer player,
    int enable,
  ) {
    return _RAPID_MediaPlayer_EnableVideoFrameDump(
      player,
      enable,
    );
  }

  late final _RAPID_MediaPlayer_EnableVideoFrameDumpPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_EnableVideoFrameDump');
  late final _RAPID_MediaPlayer_EnableVideoFrameDump =
      _RAPID_MediaPlayer_EnableVideoFrameDumpPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_EnableBuffering(
    RAPID_MediaPlayer player,
    int enable,
  ) {
    return _RAPID_MediaPlayer_EnableBuffering(
      player,
      enable,
    );
  }

  late final _RAPID_MediaPlayer_EnableBufferingPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_EnableBuffering');
  late final _RAPID_MediaPlayer_EnableBuffering =
      _RAPID_MediaPlayer_EnableBufferingPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetBufferingMode(
    RAPID_MediaPlayer player,
    int mode,
    int fixedWaterMarkMs,
  ) {
    final fn = _RAPID_MediaPlayer_SetBufferingMode;
    if (fn == null) return;
    return fn(
      player,
      mode,
      fixedWaterMarkMs,
    );
  }

  bool get supportsSetBufferingMode =>
      _RAPID_MediaPlayer_SetBufferingMode != null;

  late final _RAPID_MediaPlayer_SetBufferingModePtr = _lookupOptional<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer, ffi.Int,
              ffi.Int)>>('RAPID_MediaPlayer_SetBufferingMode');
  late final _RAPID_MediaPlayer_SetBufferingMode =
      _RAPID_MediaPlayer_SetBufferingModePtr
          ?.asFunction<void Function(RAPID_MediaPlayer, int, int)>();

  void RAPID_MediaPlayer_SetAutoMaxWaterMark(
    RAPID_MediaPlayer player,
    int value,
  ) {
    return _RAPID_MediaPlayer_SetAutoMaxWaterMark(
      player,
      value,
    );
  }

  late final _RAPID_MediaPlayer_SetAutoMaxWaterMarkPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_SetAutoMaxWaterMark');
  late final _RAPID_MediaPlayer_SetAutoMaxWaterMark =
      _RAPID_MediaPlayer_SetAutoMaxWaterMarkPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetLocalReplayAudioContinuity(
    RAPID_MediaPlayer player,
    int enabled,
  ) {
    _RAPID_MediaPlayer_SetLocalReplayAudioContinuity?.call(player, enabled);
  }

  bool get supportsSetLocalReplayAudioContinuity =>
      _RAPID_MediaPlayer_SetLocalReplayAudioContinuity != null;

  late final _RAPID_MediaPlayer_SetLocalReplayAudioContinuityPtr = _lookupOptional<
      ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
    'RAPID_MediaPlayer_SetLocalReplayAudioContinuity',
  );
  late final _RAPID_MediaPlayer_SetLocalReplayAudioContinuity =
      _RAPID_MediaPlayer_SetLocalReplayAudioContinuityPtr
          ?.asFunction<void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetClockMode(
    RAPID_MediaPlayer player,
    int mode,
  ) {
    final fn = _RAPID_MediaPlayer_SetClockMode;
    if (fn == null) return;
    return fn(
      player,
      mode,
    );
  }

  bool get supportsSetClockMode => _RAPID_MediaPlayer_SetClockMode != null;

  late final _RAPID_MediaPlayer_SetClockModePtr = _lookupOptional<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_SetClockMode');
  late final _RAPID_MediaPlayer_SetClockMode =
      _RAPID_MediaPlayer_SetClockModePtr
          ?.asFunction<void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetVideoDecoderPreference(
    RAPID_MediaPlayer player,
    int preference,
  ) {
    final fn = _RAPID_MediaPlayer_SetVideoDecoderPreference;
    if (fn == null) return;
    return fn(
      player,
      preference,
    );
  }

  bool get supportsSetVideoDecoderPreference =>
      _RAPID_MediaPlayer_SetVideoDecoderPreference != null;

  late final _RAPID_MediaPlayer_SetVideoDecoderPreferencePtr = _lookupOptional<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_SetVideoDecoderPreference');
  late final _RAPID_MediaPlayer_SetVideoDecoderPreference =
      _RAPID_MediaPlayer_SetVideoDecoderPreferencePtr
          ?.asFunction<void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetOverloadWaterMark(
    RAPID_MediaPlayer player,
    int value,
  ) {
    return _RAPID_MediaPlayer_SetOverloadWaterMark(
      player,
      value,
    );
  }

  late final _RAPID_MediaPlayer_SetOverloadWaterMarkPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_SetOverloadWaterMark');
  late final _RAPID_MediaPlayer_SetOverloadWaterMark =
      _RAPID_MediaPlayer_SetOverloadWaterMarkPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetWaterMark(
    RAPID_MediaPlayer player,
    int value,
  ) {
    return _RAPID_MediaPlayer_SetWaterMark(
      player,
      value,
    );
  }

  late final _RAPID_MediaPlayer_SetWaterMarkPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_SetWaterMark');
  late final _RAPID_MediaPlayer_SetWaterMark =
      _RAPID_MediaPlayer_SetWaterMarkPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  int RAPID_MediaPlayer_GetMuxerQueueSize(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetMuxerQueueSize(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetMuxerQueueSizePtr =
      _lookup<ffi.NativeFunction<ffi.LongLong Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_GetMuxerQueueSize');
  late final _RAPID_MediaPlayer_GetMuxerQueueSize =
      _RAPID_MediaPlayer_GetMuxerQueueSizePtr.asFunction<
          int Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_EnableAout(
    RAPID_MediaPlayer player,
    int enable,
  ) {
    return _RAPID_MediaPlayer_EnableAout(
      player,
      enable,
    );
  }

  late final _RAPID_MediaPlayer_EnableAoutPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_EnableAout');
  late final _RAPID_MediaPlayer_EnableAout = _RAPID_MediaPlayer_EnableAoutPtr
      .asFunction<void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_EnableVout(
    RAPID_MediaPlayer player,
    int enable,
  ) {
    return _RAPID_MediaPlayer_EnableVout(
      player,
      enable,
    );
  }

  late final _RAPID_MediaPlayer_EnableVoutPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.Int)>>(
      'RAPID_MediaPlayer_EnableVout');
  late final _RAPID_MediaPlayer_EnableVout = _RAPID_MediaPlayer_EnableVoutPtr
      .asFunction<void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_ConfigureAudioProcessing(
    RAPID_MediaPlayer player,
    int ns_level,
    int agc_level,
  ) {
    return _RAPID_MediaPlayer_ConfigureAudioProcessing(
      player,
      ns_level,
      agc_level,
    );
  }

  late final _RAPID_MediaPlayer_ConfigureAudioProcessingPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_MediaPlayer,
            ffi.Int32,
            ffi.Int32,
          )>>(
    'RAPID_MediaPlayer_ConfigureAudioProcessing',
  );
  late final _RAPID_MediaPlayer_ConfigureAudioProcessing =
      _RAPID_MediaPlayer_ConfigureAudioProcessingPtr.asFunction<
          void Function(RAPID_MediaPlayer, int, int)>();

  int RAPID_MediaPlayer_GetPixelWidth(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetPixelWidth(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetPixelWidthPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_GetPixelWidth');
  late final _RAPID_MediaPlayer_GetPixelWidth =
      _RAPID_MediaPlayer_GetPixelWidthPtr.asFunction<
          int Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_GetPixelHeight(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetPixelHeight(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetPixelHeightPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_GetPixelHeight');
  late final _RAPID_MediaPlayer_GetPixelHeight =
      _RAPID_MediaPlayer_GetPixelHeightPtr.asFunction<
          int Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_GetUts(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetUts(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetUtsPtr =
      _lookup<ffi.NativeFunction<ffi.LongLong Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_GetUts');
  late final _RAPID_MediaPlayer_GetUts = _RAPID_MediaPlayer_GetUtsPtr
      .asFunction<int Function(RAPID_MediaPlayer)>();

  int RAPID_MediaPlayer_GetPts(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetPts(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetPtsPtr =
      _lookup<ffi.NativeFunction<ffi.LongLong Function(RAPID_MediaPlayer)>>(
          'RAPID_MediaPlayer_GetPts');
  late final _RAPID_MediaPlayer_GetPts = _RAPID_MediaPlayer_GetPtsPtr
      .asFunction<int Function(RAPID_MediaPlayer)>();

  ffi.Pointer<RAPID_Media_PixelFrame> RAPID_MediaPlayer_GetPixelFrame(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetPixelFrame(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetPixelFramePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<RAPID_Media_PixelFrame> Function(
              RAPID_MediaPlayer)>>('RAPID_MediaPlayer_GetPixelFrame');
  late final _RAPID_MediaPlayer_GetPixelFrame =
      _RAPID_MediaPlayer_GetPixelFramePtr.asFunction<
          ffi.Pointer<RAPID_Media_PixelFrame> Function(RAPID_MediaPlayer)>();

  ffi.Pointer<RAPID_Media_PixelFrame> RAPID_Media_PixelFrame_Create() {
    return _RAPID_Media_PixelFrame_Create();
  }

  late final _RAPID_Media_PixelFrame_CreatePtr = _lookup<
          ffi.NativeFunction<ffi.Pointer<RAPID_Media_PixelFrame> Function()>>(
      'RAPID_Media_PixelFrame_Create');
  late final _RAPID_Media_PixelFrame_Create = _RAPID_Media_PixelFrame_CreatePtr
      .asFunction<ffi.Pointer<RAPID_Media_PixelFrame> Function()>();

  void RAPID_Media_PixelFrame_Free(
    ffi.Pointer<RAPID_Media_PixelFrame> frame,
  ) {
    return _RAPID_Media_PixelFrame_Free(
      frame,
    );
  }

  late final _RAPID_Media_PixelFrame_FreePtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<RAPID_Media_PixelFrame>)>>(
      'RAPID_Media_PixelFrame_Free');
  late final _RAPID_Media_PixelFrame_Free = _RAPID_Media_PixelFrame_FreePtr
      .asFunction<void Function(ffi.Pointer<RAPID_Media_PixelFrame>)>();

  void RAPID_MediaPlayer_SetPtsFunc(
    RAPID_MediaPlayer player,
    RAPID_MediaPlayer_PtsFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaPlayer_SetPtsFunc(
      player,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaPlayer_SetPtsFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_PtsFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaPlayer_SetPtsFunc');
  late final _RAPID_MediaPlayer_SetPtsFunc =
      _RAPID_MediaPlayer_SetPtsFuncPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_PtsFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaPlayer_SetPixelSizeFunc(
    RAPID_MediaPlayer player,
    RAPID_MediaPlayer_PixelSizeFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaPlayer_SetPixelSizeFunc(
      player,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaPlayer_SetPixelSizeFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_PixelSizeFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaPlayer_SetPixelSizeFunc');
  late final _RAPID_MediaPlayer_SetPixelSizeFunc =
      _RAPID_MediaPlayer_SetPixelSizeFuncPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_PixelSizeFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaPlayer_SetUtsFunc(
    RAPID_MediaPlayer player,
    RAPID_MediaPlayer_UtsFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaPlayer_SetUtsFunc(
      player,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaPlayer_SetUtsFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_UtsFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaPlayer_SetUtsFunc');
  late final _RAPID_MediaPlayer_SetUtsFunc =
      _RAPID_MediaPlayer_SetUtsFuncPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_UtsFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaPlayer_SetRenderStateFunc(
    RAPID_MediaPlayer player,
    RAPID_MediaPlayer_StateFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaPlayer_SetRenderStateFunc(
      player,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaPlayer_SetRenderStateFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_StateFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaPlayer_SetRenderStateFunc');
  late final _RAPID_MediaPlayer_SetRenderStateFunc =
      _RAPID_MediaPlayer_SetRenderStateFuncPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_StateFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaPlayer_SetPixelFunc(
    RAPID_MediaPlayer player,
    RAPID_MediaPlayer_PixelFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaPlayer_SetPixelFunc(
      player,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaPlayer_SetPixelFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_PixelFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaPlayer_SetPixelFunc');
  late final _RAPID_MediaPlayer_SetPixelFunc =
      _RAPID_MediaPlayer_SetPixelFuncPtr.asFunction<
          void Function(RAPID_MediaPlayer, RAPID_MediaPlayer_PixelFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaPlayer_SetRenderStatusSendPort(
    RAPID_MediaPlayer player,
    int port,
  ) {
    return _RAPID_MediaPlayer_SetRenderStatusSendPort(
      player,
      port,
    );
  }

  late final _RAPID_MediaPlayer_SetRenderStatusSendPortPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.LongLong)>>(
      'RAPID_MediaPlayer_SetRenderStatusSendPort');
  late final _RAPID_MediaPlayer_SetRenderStatusSendPort =
      _RAPID_MediaPlayer_SetRenderStatusSendPortPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetRecordDurationSendPort(
    RAPID_MediaPlayer player,
    int port,
  ) {
    final fn = _RAPID_MediaPlayer_SetRecordDurationSendPort;
    if (fn == null) return;
    return fn(
      player,
      port,
    );
  }

  bool get supportsRecordDurationSendPort =>
      _RAPID_MediaPlayer_SetRecordDurationSendPort != null;

  late final _RAPID_MediaPlayer_SetRecordDurationSendPortPtr = _lookupOptional<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.LongLong)>>(
      'RAPID_MediaPlayer_SetRecordDurationSendPort');
  late final _RAPID_MediaPlayer_SetRecordDurationSendPort =
      _RAPID_MediaPlayer_SetRecordDurationSendPortPtr
          ?.asFunction<void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetPtsSendPort(
    RAPID_MediaPlayer player,
    int port,
  ) {
    return _RAPID_MediaPlayer_SetPtsSendPort(player, port);
  }

  late final _RAPID_MediaPlayer_SetPtsSendPortPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.LongLong)>>(
      'RAPID_MediaPlayer_SetPtsSendPort');
  late final _RAPID_MediaPlayer_SetPtsSendPort =
      _RAPID_MediaPlayer_SetPtsSendPortPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  void RAPID_MediaPlayer_SetUtsSendPort(
    RAPID_MediaPlayer player,
    int port,
  ) {
    return _RAPID_MediaPlayer_SetUtsSendPort(player, port);
  }

  late final _RAPID_MediaPlayer_SetUtsSendPortPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_MediaPlayer, ffi.LongLong)>>(
      'RAPID_MediaPlayer_SetUtsSendPort');
  late final _RAPID_MediaPlayer_SetUtsSendPort =
      _RAPID_MediaPlayer_SetUtsSendPortPtr.asFunction<
          void Function(RAPID_MediaPlayer, int)>();

  ffi.Pointer<Utf8> RAPID_MediaPlayer_GetRuntimeMetricsJson(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetRuntimeMetricsJson(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetRuntimeMetricsJsonPtr = _lookup<
      ffi.NativeFunction<ffi.Pointer<Utf8> Function(RAPID_MediaPlayer)>>(
    'RAPID_MediaPlayer_GetRuntimeMetricsJson',
  );
  late final _RAPID_MediaPlayer_GetRuntimeMetricsJson =
      _RAPID_MediaPlayer_GetRuntimeMetricsJsonPtr.asFunction<
          ffi.Pointer<Utf8> Function(RAPID_MediaPlayer)>();

  ffi.Pointer<Utf8> RAPID_MediaPlayer_GetStartupMetricsJson(
    RAPID_MediaPlayer player,
  ) {
    return _RAPID_MediaPlayer_GetStartupMetricsJson(
      player,
    );
  }

  late final _RAPID_MediaPlayer_GetStartupMetricsJsonPtr = _lookup<
      ffi.NativeFunction<ffi.Pointer<Utf8> Function(RAPID_MediaPlayer)>>(
    'RAPID_MediaPlayer_GetStartupMetricsJson',
  );
  late final _RAPID_MediaPlayer_GetStartupMetricsJson =
      _RAPID_MediaPlayer_GetStartupMetricsJsonPtr.asFunction<
          ffi.Pointer<Utf8> Function(RAPID_MediaPlayer)>();

  void RAPID_MediaPlayer_FreeJson(
    ffi.Pointer<Utf8> json,
  ) {
    return _RAPID_MediaPlayer_FreeJson(
      json,
    );
  }

  late final _RAPID_MediaPlayer_FreeJsonPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>(
    'RAPID_MediaPlayer_FreeJson',
  );
  late final _RAPID_MediaPlayer_FreeJson = _RAPID_MediaPlayer_FreeJsonPtr
      .asFunction<void Function(ffi.Pointer<Utf8>)>();
}

abstract class RAPID_MediaRenderState {
  static const int RAPID_MEDIA_RENDER_STATE_UNKNOWN = -1;
  static const int RAPID_MEDIA_RENDER_STATE_STARTED = 0;
  static const int RAPID_MEDIA_RENDER_STATE_BUFFERING = 1;
  static const int RAPID_MEDIA_RENDER_STATE_COMPLETED = 2;
  static const int RAPID_MEDIA_RENDER_STATE_PAUSED = 3;
}

class RAPID_Media_PixelFrame extends ffi.Struct {
  @ffi.Int()
  external int width;

  @ffi.Int()
  external int height;

  @ffi.Int()
  external int pixel_format;

  @ffi.Int()
  external int data_size;

  external ffi.Pointer<ffi.UnsignedChar> data;
}

typedef RAPID_MediaPlayer = ffi.Pointer<ffi.Void>;
typedef RAPID_SDL_Vout_Opaque_Ptr = ffi.Pointer<ffi.Void>;
typedef RAPID_SDL_Aout_Opaque_Ptr = ffi.Pointer<ffi.Void>;
typedef RAPID_MediaPlayer_PtsFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaPlayer_PtsFuncFunction>>;
typedef RAPID_MediaPlayer_PtsFuncFunction = ffi.Void Function(
    ffi.LongLong pts, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaPlayer_PtsFuncFunction = void Function(
    int pts, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_MediaPlayer_PixelSizeFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaPlayer_PixelSizeFuncFunction>>;
typedef RAPID_MediaPlayer_PixelSizeFuncFunction = ffi.Void Function(
    ffi.Int width, ffi.Int height, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaPlayer_PixelSizeFuncFunction = void Function(
    int width, int height, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_MediaPlayer_UtsFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaPlayer_UtsFuncFunction>>;
typedef RAPID_MediaPlayer_UtsFuncFunction = ffi.Void Function(
    ffi.LongLong uts, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaPlayer_UtsFuncFunction = void Function(
    int uts, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_MediaPlayer_StateFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaPlayer_StateFuncFunction>>;
typedef RAPID_MediaPlayer_StateFuncFunction = ffi.Void Function(
    ffi.Int render_state, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaPlayer_StateFuncFunction = void Function(
    int render_state, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_MediaPlayer_PixelFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaPlayer_PixelFuncFunction>>;
typedef RAPID_MediaPlayer_PixelFuncFunction = ffi.Void Function(
    ffi.Int width,
    ffi.Int height,
    ffi.Int pixel_format,
    ffi.Int data_size,
    ffi.Pointer<ffi.UnsignedChar> data,
    ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaPlayer_PixelFuncFunction = void Function(
    int width,
    int height,
    int pixel_format,
    int data_size,
    ffi.Pointer<ffi.UnsignedChar> data,
    ffi.Pointer<ffi.Void> user_data);
