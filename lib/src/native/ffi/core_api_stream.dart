// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

const int RAPID_Core_LocalReplayTimezone_Unspecified = -1;

class CoreApiStreamBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  CoreApiStreamBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  CoreApiStreamBinding.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateDefault(
    ffi.Pointer<ffi.Void> pipe_proxy,
  ) {
    return _RAPID_Core_LiveStream_CreateDefault(pipe_proxy);
  }

  late final _RAPID_Core_LiveStream_CreateDefaultPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_LiveStream Function(
              ffi.Pointer<ffi.Void>)>>('RAPID_Core_LiveStream_CreateDefault');
  late final _RAPID_Core_LiveStream_CreateDefault =
      _RAPID_Core_LiveStream_CreateDefaultPtr.asFunction<
          RAPID_Core_LiveStream Function(ffi.Pointer<ffi.Void>)>();

  RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateDefaultWithAudio(
    ffi.Pointer<ffi.Void> pipe_proxy,
    int audio_enable,
  ) {
    return _RAPID_Core_LiveStream_CreateDefaultWithAudio(
      pipe_proxy,
      audio_enable,
    );
  }

  late final _RAPID_Core_LiveStream_CreateDefaultWithAudioPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_LiveStream Function(ffi.Pointer<ffi.Void>,
              ffi.Int)>>('RAPID_Core_LiveStream_CreateDefaultWithAudio');
  late final _RAPID_Core_LiveStream_CreateDefaultWithAudio =
      _RAPID_Core_LiveStream_CreateDefaultWithAudioPtr.asFunction<
          RAPID_Core_LiveStream Function(ffi.Pointer<ffi.Void>, int)>();

  RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateSecondary(
    ffi.Pointer<ffi.Void> pipe_proxy,
  ) {
    return _RAPID_Core_LiveStream_CreateSecondary(pipe_proxy);
  }

  late final _RAPID_Core_LiveStream_CreateSecondaryPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_LiveStream Function(
              ffi.Pointer<ffi.Void>)>>('RAPID_Core_LiveStream_CreateSecondary');
  late final _RAPID_Core_LiveStream_CreateSecondary =
      _RAPID_Core_LiveStream_CreateSecondaryPtr.asFunction<
          RAPID_Core_LiveStream Function(ffi.Pointer<ffi.Void>)>();

  RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateSecondaryWithAudio(
    ffi.Pointer<ffi.Void> pipe_proxy,
  ) {
    return _RAPID_Core_LiveStream_CreateSecondaryWithAudio(pipe_proxy);
  }

  late final _RAPID_Core_LiveStream_CreateSecondaryWithAudioPtr = _lookup<
          ffi.NativeFunction<
              RAPID_Core_LiveStream Function(ffi.Pointer<ffi.Void>)>>(
      'RAPID_Core_LiveStream_CreateSecondaryWithAudio');
  late final _RAPID_Core_LiveStream_CreateSecondaryWithAudio =
      _RAPID_Core_LiveStream_CreateSecondaryWithAudioPtr.asFunction<
          RAPID_Core_LiveStream Function(ffi.Pointer<ffi.Void>)>();

  void RAPID_Core_LiveStream_Start(RAPID_Core_LiveStream live_stream) {
    return _RAPID_Core_LiveStream_Start(live_stream);
  }

  late final _RAPID_Core_LiveStream_StartPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_Start',
  );
  late final _RAPID_Core_LiveStream_Start = _RAPID_Core_LiveStream_StartPtr
      .asFunction<void Function(RAPID_Core_LiveStream)>();

  void RAPID_Core_LiveStream_Stop(RAPID_Core_LiveStream live_stream) {
    return _RAPID_Core_LiveStream_Stop(live_stream);
  }

  late final _RAPID_Core_LiveStream_StopPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_Stop',
  );
  late final _RAPID_Core_LiveStream_Stop = _RAPID_Core_LiveStream_StopPtr
      .asFunction<void Function(RAPID_Core_LiveStream)>();

  int RAPID_Core_LiveStream_IsStarted(RAPID_Core_LiveStream live_stream) {
    return _RAPID_Core_LiveStream_IsStarted(live_stream);
  }

  late final _RAPID_Core_LiveStream_IsStartedPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_IsStarted',
  );
  late final _RAPID_Core_LiveStream_IsStarted =
      _RAPID_Core_LiveStream_IsStartedPtr.asFunction<
          int Function(RAPID_Core_LiveStream)>();

  void RAPID_Core_LiveStream_SwitchQuality(
    RAPID_Core_LiveStream live_stream,
    int quality,
  ) {
    return _RAPID_Core_LiveStream_SwitchQuality(live_stream, quality);
  }

  late final _RAPID_Core_LiveStream_SwitchQualityPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_Core_LiveStream, ffi.Int)>>(
      'RAPID_Core_LiveStream_SwitchQuality');
  late final _RAPID_Core_LiveStream_SwitchQuality =
      _RAPID_Core_LiveStream_SwitchQualityPtr.asFunction<
          void Function(RAPID_Core_LiveStream, int)>();

  void RAPID_Core_LiveStream_SwitchHighQuality(
    RAPID_Core_LiveStream live_stream,
  ) {
    return _RAPID_Core_LiveStream_SwitchHighQuality(live_stream);
  }

  late final _RAPID_Core_LiveStream_SwitchHighQualityPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_SwitchHighQuality',
  );
  late final _RAPID_Core_LiveStream_SwitchHighQuality =
      _RAPID_Core_LiveStream_SwitchHighQualityPtr.asFunction<
          void Function(RAPID_Core_LiveStream)>();

  void RAPID_Core_LiveStream_SwitchLowQuality(
    RAPID_Core_LiveStream live_stream,
  ) {
    return _RAPID_Core_LiveStream_SwitchLowQuality(live_stream);
  }

  late final _RAPID_Core_LiveStream_SwitchLowQualityPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_SwitchLowQuality',
  );
  late final _RAPID_Core_LiveStream_SwitchLowQuality =
      _RAPID_Core_LiveStream_SwitchLowQualityPtr.asFunction<
          void Function(RAPID_Core_LiveStream)>();

  int RAPID_Core_LiveStream_CurrentQuality(RAPID_Core_LiveStream live_stream) {
    return _RAPID_Core_LiveStream_CurrentQuality(live_stream);
  }

  late final _RAPID_Core_LiveStream_CurrentQualityPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_CurrentQuality',
  );
  late final _RAPID_Core_LiveStream_CurrentQuality =
      _RAPID_Core_LiveStream_CurrentQualityPtr.asFunction<
          int Function(RAPID_Core_LiveStream)>();

  void RAPID_Core_LiveStream_RequestKeyFrame(
    RAPID_Core_LiveStream live_stream,
  ) {
    return _RAPID_Core_LiveStream_RequestKeyFrame(live_stream);
  }

  late final _RAPID_Core_LiveStream_RequestKeyFramePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_RequestKeyFrame',
  );
  late final _RAPID_Core_LiveStream_RequestKeyFrame =
      _RAPID_Core_LiveStream_RequestKeyFramePtr.asFunction<
          void Function(RAPID_Core_LiveStream)>();

  void RAPID_Core_LiveStream_Release(RAPID_Core_LiveStream live_stream) {
    return _RAPID_Core_LiveStream_Release(live_stream);
  }

  late final _RAPID_Core_LiveStream_ReleasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LiveStream)>>(
    'RAPID_Core_LiveStream_Release',
  );
  late final _RAPID_Core_LiveStream_Release = _RAPID_Core_LiveStream_ReleasePtr
      .asFunction<void Function(RAPID_Core_LiveStream)>();

  RAPID_Core_StreamProvider RAPID_Core_LiveStream_IndexedProvider(
    RAPID_Core_LiveStream live_stream,
    int index,
  ) {
    return _RAPID_Core_LiveStream_IndexedProvider(live_stream, index);
  }

  late final _RAPID_Core_LiveStream_IndexedProviderPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_StreamProvider Function(
            RAPID_Core_LiveStream,
            ffi.UnsignedInt,
          )>>('RAPID_Core_LiveStream_IndexedProvider');
  late final _RAPID_Core_LiveStream_IndexedProvider =
      _RAPID_Core_LiveStream_IndexedProviderPtr.asFunction<
          RAPID_Core_StreamProvider Function(RAPID_Core_LiveStream, int)>();

  ffi.Pointer<Utf8> RAPID_Core_LiveStream_GetReceiveMetrics(
    RAPID_Core_LiveStream live_stream,
    int camera_index,
  ) {
    return _RAPID_Core_LiveStream_GetReceiveMetrics(live_stream, camera_index);
  }

  late final _RAPID_Core_LiveStream_GetReceiveMetricsPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<Utf8> Function(RAPID_Core_LiveStream,
              ffi.UnsignedInt)>>('RAPID_Core_LiveStream_GetReceiveMetrics');
  late final _RAPID_Core_LiveStream_GetReceiveMetrics =
      _RAPID_Core_LiveStream_GetReceiveMetricsPtr.asFunction<
          ffi.Pointer<Utf8> Function(RAPID_Core_LiveStream, int)>();

  ffi.Pointer<Utf8> RAPID_Core_LiveStream_GetMetrics(
    RAPID_Core_LiveStream live_stream,
    int camera_index,
  ) {
    return _RAPID_Core_LiveStream_GetMetrics(live_stream, camera_index);
  }

  late final _RAPID_Core_LiveStream_GetMetricsPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<Utf8> Function(RAPID_Core_LiveStream,
              ffi.UnsignedInt)>>('RAPID_Core_LiveStream_GetMetrics');
  late final _RAPID_Core_LiveStream_GetMetrics =
      _RAPID_Core_LiveStream_GetMetricsPtr.asFunction<
          ffi.Pointer<Utf8> Function(RAPID_Core_LiveStream, int)>();

  ffi.Pointer<Utf8> RAPID_Core_LiveStream_GetFirstPacketMetricsJson(
    RAPID_Core_LiveStream live_stream,
    int camera_index,
  ) {
    return _RAPID_Core_LiveStream_GetFirstPacketMetricsJson(
      live_stream,
      camera_index,
    );
  }

  late final _RAPID_Core_LiveStream_GetFirstPacketMetricsJsonPtr = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<Utf8> Function(
                  RAPID_Core_LiveStream, ffi.UnsignedInt)>>(
      'RAPID_Core_LiveStream_GetFirstPacketMetricsJson');
  late final _RAPID_Core_LiveStream_GetFirstPacketMetricsJson =
      _RAPID_Core_LiveStream_GetFirstPacketMetricsJsonPtr.asFunction<
          ffi.Pointer<Utf8> Function(RAPID_Core_LiveStream, int)>();

  void RAPID_Core_LiveStream_FreeMetrics(ffi.Pointer<Utf8> json) {
    return _RAPID_Core_LiveStream_FreeMetrics(json);
  }

  late final _RAPID_Core_LiveStream_FreeMetricsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>(
    'RAPID_Core_LiveStream_FreeMetrics',
  );
  late final _RAPID_Core_LiveStream_FreeMetrics =
      _RAPID_Core_LiveStream_FreeMetricsPtr.asFunction<
          void Function(ffi.Pointer<Utf8>)>();

  RAPID_Core_LocalReplayStream RAPID_Core_LocalReplayStream_Create(
    ffi.Pointer<ffi.Void> pipe_proxy,
  ) {
    return _RAPID_Core_LocalReplayStream_Create(pipe_proxy);
  }

  late final _RAPID_Core_LocalReplayStream_CreatePtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_LocalReplayStream Function(
              ffi.Pointer<ffi.Void>)>>('RAPID_Core_LocalReplayStream_Create');
  late final _RAPID_Core_LocalReplayStream_Create =
      _RAPID_Core_LocalReplayStream_CreatePtr.asFunction<
          RAPID_Core_LocalReplayStream Function(ffi.Pointer<ffi.Void>)>();

  RAPID_Core_LocalReplayStream RAPID_Core_LocalReplayStream_CreateWithAudio(
    ffi.Pointer<ffi.Void> pipe_proxy,
    int audio_enable,
  ) {
    return _RAPID_Core_LocalReplayStream_CreateWithAudio(
      pipe_proxy,
      audio_enable,
    );
  }

  late final _RAPID_Core_LocalReplayStream_CreateWithAudioPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_LocalReplayStream Function(ffi.Pointer<ffi.Void>,
              ffi.Int)>>('RAPID_Core_LocalReplayStream_CreateWithAudio');
  late final _RAPID_Core_LocalReplayStream_CreateWithAudio =
      _RAPID_Core_LocalReplayStream_CreateWithAudioPtr.asFunction<
          RAPID_Core_LocalReplayStream Function(ffi.Pointer<ffi.Void>, int)>();

  void RAPID_Core_LocalReplayStream_SetAudioUtcFallback(
    RAPID_Core_LocalReplayStream local_stream,
    int enabled,
  ) {
    _RAPID_Core_LocalReplayStream_SetAudioUtcFallback(local_stream, enabled);
  }

  late final _RAPID_Core_LocalReplayStream_SetAudioUtcFallbackPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_LocalReplayStream, ffi.Int)>>(
    'RAPID_Core_LocalReplayStream_SetAudioUtcFallback',
  );
  late final _RAPID_Core_LocalReplayStream_SetAudioUtcFallback =
      _RAPID_Core_LocalReplayStream_SetAudioUtcFallbackPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int)>();

  void RAPID_Core_LocalReplayStream_SetSeekErrorSendPort(
    RAPID_Core_LocalReplayStream local_stream,
    int port,
  ) {
    _RAPID_Core_LocalReplayStream_SetSeekErrorSendPort(local_stream, port);
  }

  late final _RAPID_Core_LocalReplayStream_SetSeekErrorSendPortPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(RAPID_Core_LocalReplayStream, ffi.LongLong)>>(
      'RAPID_Core_LocalReplayStream_SetSeekErrorSendPort');
  late final _RAPID_Core_LocalReplayStream_SetSeekErrorSendPort =
      _RAPID_Core_LocalReplayStream_SetSeekErrorSendPortPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int)>();

  void RAPID_Core_LocalReplayStream_Start(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_Start(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_StartPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_Start');
  late final _RAPID_Core_LocalReplayStream_Start =
      _RAPID_Core_LocalReplayStream_StartPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream)>();

  void RAPID_Core_LocalReplayStream_CompatibleOnResumeInstruct(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_CompatibleOnResumeInstruct(
      local_stream,
    );
  }

  late final _RAPID_Core_LocalReplayStream_CompatibleOnResumeInstructPtr =
      _lookup<
              ffi
              .NativeFunction<ffi.Void Function(RAPID_Core_LocalReplayStream)>>(
          'RAPID_Core_LocalReplayStream_CompatibleOnResumeInstruct');
  late final _RAPID_Core_LocalReplayStream_CompatibleOnResumeInstruct =
      _RAPID_Core_LocalReplayStream_CompatibleOnResumeInstructPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream)>();

  void RAPID_Core_LocalReplayStream_Prepare(
    RAPID_Core_LocalReplayStream local_stream,
    int start_timestamp_s,
    int end_timestamp_s,
  ) {
    return _RAPID_Core_LocalReplayStream_Prepare(
      local_stream,
      start_timestamp_s,
      end_timestamp_s,
    );
  }

  late final _RAPID_Core_LocalReplayStream_PreparePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_LocalReplayStream,
            ffi.UnsignedInt,
            ffi.UnsignedInt,
          )>>('RAPID_Core_LocalReplayStream_Prepare');
  late final _RAPID_Core_LocalReplayStream_Prepare =
      _RAPID_Core_LocalReplayStream_PreparePtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int, int)>();

  void RAPID_Core_LocalReplayStream_Stop(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_Stop(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_StopPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_Stop');
  late final _RAPID_Core_LocalReplayStream_Stop =
      _RAPID_Core_LocalReplayStream_StopPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream)>();

  int RAPID_Core_LocalReplayStream_IsStarted(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_IsStarted(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_IsStartedPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_IsStarted');
  late final _RAPID_Core_LocalReplayStream_IsStarted =
      _RAPID_Core_LocalReplayStream_IsStartedPtr.asFunction<
          int Function(RAPID_Core_LocalReplayStream)>();

  void RAPID_Core_LocalReplayStream_Seek(
    RAPID_Core_LocalReplayStream local_stream,
    int timestamp,
  ) {
    return _RAPID_Core_LocalReplayStream_Seek(local_stream, timestamp);
  }

  late final _RAPID_Core_LocalReplayStream_SeekPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_LocalReplayStream,
              ffi.LongLong)>>('RAPID_Core_LocalReplayStream_Seek');
  late final _RAPID_Core_LocalReplayStream_Seek =
      _RAPID_Core_LocalReplayStream_SeekPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int)>();

  void RAPID_Core_LocalReplayStream_SeekWithModeAndTimezone(
    RAPID_Core_LocalReplayStream local_stream,
    int timestamp,
    int start_mode,
    int timezone_offset_s,
  ) {
    return _RAPID_Core_LocalReplayStream_SeekWithModeAndTimezone(
      local_stream,
      timestamp,
      start_mode,
      timezone_offset_s,
    );
  }

  late final _RAPID_Core_LocalReplayStream_SeekWithModeAndTimezonePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              RAPID_Core_LocalReplayStream, ffi.LongLong, ffi.Int, ffi.Int)>>(
    'RAPID_Core_LocalReplayStream_SeekWithModeAndTimezone',
  );
  late final _RAPID_Core_LocalReplayStream_SeekWithModeAndTimezone =
      _RAPID_Core_LocalReplayStream_SeekWithModeAndTimezonePtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int, int, int)>();

  void RAPID_Core_LocalReplayStream_UpdateLastRenderedUtc(
    RAPID_Core_LocalReplayStream local_stream,
    int timestamp_ms,
  ) {
    return _RAPID_Core_LocalReplayStream_UpdateLastRenderedUtc(
      local_stream,
      timestamp_ms,
    );
  }

  late final _RAPID_Core_LocalReplayStream_UpdateLastRenderedUtcPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(RAPID_Core_LocalReplayStream, ffi.LongLong)>>(
      'RAPID_Core_LocalReplayStream_UpdateLastRenderedUtc');
  late final _RAPID_Core_LocalReplayStream_UpdateLastRenderedUtc =
      _RAPID_Core_LocalReplayStream_UpdateLastRenderedUtcPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int)>();

  void RAPID_Core_LocalReplayStream_SetSpeed(
    RAPID_Core_LocalReplayStream local_stream,
    int speed,
  ) {
    return _RAPID_Core_LocalReplayStream_SetSpeed(local_stream, speed);
  }

  late final _RAPID_Core_LocalReplayStream_SetSpeedPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_LocalReplayStream,
              ffi.Int)>>('RAPID_Core_LocalReplayStream_SetSpeed');
  late final _RAPID_Core_LocalReplayStream_SetSpeed =
      _RAPID_Core_LocalReplayStream_SetSpeedPtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream, int)>();

  void RAPID_Core_LocalReplayStream_Pause(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_Pause(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_PausePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_Pause');
  late final _RAPID_Core_LocalReplayStream_Pause =
      _RAPID_Core_LocalReplayStream_PausePtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream)>();

  int RAPID_Core_LocalReplayStream_IsPaused(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_IsPaused(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_IsPausedPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_IsPaused');
  late final _RAPID_Core_LocalReplayStream_IsPaused =
      _RAPID_Core_LocalReplayStream_IsPausedPtr.asFunction<
          int Function(RAPID_Core_LocalReplayStream)>();

  void RAPID_Core_LocalReplayStream_Resume(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_Resume(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_ResumePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_Resume');
  late final _RAPID_Core_LocalReplayStream_Resume =
      _RAPID_Core_LocalReplayStream_ResumePtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream)>();

  void RAPID_Core_LocalReplayStream_Release(
    RAPID_Core_LocalReplayStream local_stream,
  ) {
    return _RAPID_Core_LocalReplayStream_Release(local_stream);
  }

  late final _RAPID_Core_LocalReplayStream_ReleasePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_LocalReplayStream)>>(
      'RAPID_Core_LocalReplayStream_Release');
  late final _RAPID_Core_LocalReplayStream_Release =
      _RAPID_Core_LocalReplayStream_ReleasePtr.asFunction<
          void Function(RAPID_Core_LocalReplayStream)>();

  RAPID_Core_StreamProvider RAPID_Core_LocalReplayStream_IndexedProvider(
    RAPID_Core_LocalReplayStream local_stream,
    int index,
  ) {
    return _RAPID_Core_LocalReplayStream_IndexedProvider(local_stream, index);
  }

  late final _RAPID_Core_LocalReplayStream_IndexedProviderPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_StreamProvider Function(
            RAPID_Core_LocalReplayStream,
            ffi.UnsignedInt,
          )>>('RAPID_Core_LocalReplayStream_IndexedProvider');
  late final _RAPID_Core_LocalReplayStream_IndexedProvider =
      _RAPID_Core_LocalReplayStream_IndexedProviderPtr.asFunction<
          RAPID_Core_StreamProvider Function(
              RAPID_Core_LocalReplayStream, int)>();

  RAPID_Core_CloudReplayStream RAPID_Core_CloudReplayStream_Create(
    ffi.Pointer<Utf8> device_id,
  ) {
    return _RAPID_Core_CloudReplayStream_Create(device_id);
  }

  late final _RAPID_Core_CloudReplayStream_CreatePtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_CloudReplayStream Function(
              ffi.Pointer<Utf8>)>>('RAPID_Core_CloudReplayStream_Create');
  late final _RAPID_Core_CloudReplayStream_Create =
      _RAPID_Core_CloudReplayStream_CreatePtr.asFunction<
          RAPID_Core_CloudReplayStream Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_CloudReplayStream_Prepare(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int start_timestamp_s,
    int end_timestamp_s,
    ffi.Pointer<Utf8> storage_id,
    ffi.Pointer<Utf8> file_name_list_json,
  ) {
    return _RAPID_Core_CloudReplayStream_Prepare(
      cloud_replay_stream,
      start_timestamp_s,
      end_timestamp_s,
      storage_id,
      file_name_list_json,
    );
  }

  late final _RAPID_Core_CloudReplayStream_PreparePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_CloudReplayStream,
            ffi.UnsignedInt,
            ffi.UnsignedInt,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
          )>>('RAPID_Core_CloudReplayStream_Prepare');
  late final _RAPID_Core_CloudReplayStream_Prepare =
      _RAPID_Core_CloudReplayStream_PreparePtr.asFunction<
          void Function(
            RAPID_Core_CloudReplayStream,
            int,
            int,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
          )>();

  void RAPID_Core_CloudReplayStream_PrepareV2(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int start_timestamp_s,
    int end_timestamp_s,
    ffi.Pointer<Utf8> storage_id,
    ffi.Pointer<Utf8> file_name_list_json,
    int replay_mode,
  ) {
    return _RAPID_Core_CloudReplayStream_PrepareV2(
      cloud_replay_stream,
      start_timestamp_s,
      end_timestamp_s,
      storage_id,
      file_name_list_json,
      replay_mode,
    );
  }

  late final _RAPID_Core_CloudReplayStream_PrepareV2Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_CloudReplayStream,
            ffi.UnsignedInt,
            ffi.UnsignedInt,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
            ffi.Int,
          )>>('RAPID_Core_CloudReplayStream_PrepareV2');
  late final _RAPID_Core_CloudReplayStream_PrepareV2 =
      _RAPID_Core_CloudReplayStream_PrepareV2Ptr.asFunction<
          void Function(
            RAPID_Core_CloudReplayStream,
            int,
            int,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
            int,
          )>();

  void RAPID_Core_CloudReplayStream_Start(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_Start(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_StartPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_Start');
  late final _RAPID_Core_CloudReplayStream_Start =
      _RAPID_Core_CloudReplayStream_StartPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream)>();

  RAPID_Core_CloudReplayDownloadStartResult
      RAPID_Core_CloudReplayStream_StartDownload(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int start_timestamp_s,
    int end_timestamp_s,
    ffi.Pointer<Utf8> storage_id,
    ffi.Pointer<Utf8> file_name_list_json,
  ) {
    return _RAPID_Core_CloudReplayStream_StartDownload(
      cloud_replay_stream,
      start_timestamp_s,
      end_timestamp_s,
      storage_id,
      file_name_list_json,
    );
  }

  late final _RAPID_Core_CloudReplayStream_StartDownloadPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_CloudReplayDownloadStartResult Function(
            RAPID_Core_CloudReplayStream,
            ffi.LongLong,
            ffi.LongLong,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
          )>>('RAPID_Core_CloudReplayStream_StartDownload');
  late final _RAPID_Core_CloudReplayStream_StartDownload =
      _RAPID_Core_CloudReplayStream_StartDownloadPtr.asFunction<
          RAPID_Core_CloudReplayDownloadStartResult Function(
            RAPID_Core_CloudReplayStream,
            int,
            int,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
          )>();

  void RAPID_Core_CloudReplayStream_Seek(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int timestamp_s,
  ) {
    return _RAPID_Core_CloudReplayStream_Seek(cloud_replay_stream, timestamp_s);
  }

  late final _RAPID_Core_CloudReplayStream_SeekPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_CloudReplayStream,
              ffi.UnsignedInt)>>('RAPID_Core_CloudReplayStream_Seek');
  late final _RAPID_Core_CloudReplayStream_Seek =
      _RAPID_Core_CloudReplayStream_SeekPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream, int)>();

  void RAPID_Core_CloudReplayStream_SetSpeed(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int speed,
  ) {
    return _RAPID_Core_CloudReplayStream_SetSpeed(cloud_replay_stream, speed);
  }

  late final _RAPID_Core_CloudReplayStream_SetSpeedPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_CloudReplayStream,
              ffi.Int)>>('RAPID_Core_CloudReplayStream_SetSpeed');
  late final _RAPID_Core_CloudReplayStream_SetSpeed =
      _RAPID_Core_CloudReplayStream_SetSpeedPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream, int)>();

  void RAPID_Core_CloudReplayStream_Pause(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_Pause(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_PausePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_Pause');
  late final _RAPID_Core_CloudReplayStream_Pause =
      _RAPID_Core_CloudReplayStream_PausePtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream)>();

  void RAPID_Core_CloudReplayStream_Resume(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_Resume(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_ResumePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_Resume');
  late final _RAPID_Core_CloudReplayStream_Resume =
      _RAPID_Core_CloudReplayStream_ResumePtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream)>();

  void RAPID_Core_CloudReplayStream_Stop(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_Stop(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_StopPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_Stop');
  late final _RAPID_Core_CloudReplayStream_Stop =
      _RAPID_Core_CloudReplayStream_StopPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream)>();

  int RAPID_Core_CloudReplayStream_IsPaused(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_IsPaused(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_IsPausedPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_IsPaused');
  late final _RAPID_Core_CloudReplayStream_IsPaused =
      _RAPID_Core_CloudReplayStream_IsPausedPtr.asFunction<
          int Function(RAPID_Core_CloudReplayStream)>();

  int RAPID_Core_CloudReplayStream_IsStarted(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_IsStarted(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_IsStartedPtr = _lookup<
          ffi.NativeFunction<ffi.Int Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_IsStarted');
  late final _RAPID_Core_CloudReplayStream_IsStarted =
      _RAPID_Core_CloudReplayStream_IsStartedPtr.asFunction<
          int Function(RAPID_Core_CloudReplayStream)>();

  void RAPID_Core_CloudReplayStream_Release(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
  ) {
    return _RAPID_Core_CloudReplayStream_Release(cloud_replay_stream);
  }

  late final _RAPID_Core_CloudReplayStream_ReleasePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(RAPID_Core_CloudReplayStream)>>(
      'RAPID_Core_CloudReplayStream_Release');
  late final _RAPID_Core_CloudReplayStream_Release =
      _RAPID_Core_CloudReplayStream_ReleasePtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream)>();

  void RAPID_Core_CloudReplayStream_SetFileNotFoundFunc(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    RAPID_Core_CloudReplayStream_FileNotFoundFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_Core_CloudReplayStream_SetFileNotFoundFunc(
      cloud_replay_stream,
      func,
      user_data,
    );
  }

  late final _RAPID_Core_CloudReplayStream_SetFileNotFoundFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_CloudReplayStream,
            RAPID_Core_CloudReplayStream_FileNotFoundFunc,
            ffi.Pointer<ffi.Void>,
          )>>('RAPID_Core_CloudReplayStream_SetFileNotFoundFunc');
  late final _RAPID_Core_CloudReplayStream_SetFileNotFoundFunc =
      _RAPID_Core_CloudReplayStream_SetFileNotFoundFuncPtr.asFunction<
          void Function(
            RAPID_Core_CloudReplayStream,
            RAPID_Core_CloudReplayStream_FileNotFoundFunc,
            ffi.Pointer<ffi.Void>,
          )>();

  void RAPID_Core_CloudReplayStream_SetDownloadCompleteFunc(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    RAPID_Core_CloudReplayStream_DownloadCompleteFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_Core_CloudReplayStream_SetDownloadCompleteFunc(
      cloud_replay_stream,
      func,
      user_data,
    );
  }

  late final _RAPID_Core_CloudReplayStream_SetDownloadCompleteFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_CloudReplayStream,
            RAPID_Core_CloudReplayStream_DownloadCompleteFunc,
            ffi.Pointer<ffi.Void>,
          )>>('RAPID_Core_CloudReplayStream_SetDownloadCompleteFunc');
  late final _RAPID_Core_CloudReplayStream_SetDownloadCompleteFunc =
      _RAPID_Core_CloudReplayStream_SetDownloadCompleteFuncPtr.asFunction<
          void Function(
            RAPID_Core_CloudReplayStream,
            RAPID_Core_CloudReplayStream_DownloadCompleteFunc,
            ffi.Pointer<ffi.Void>,
          )>();

  void RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPort(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int port,
  ) {
    return _RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPort(
      cloud_replay_stream,
      port,
    );
  }

  late final _RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPortPtr =
      _lookup<
              ffi.NativeFunction<
                  ffi.Void Function(
                      RAPID_Core_CloudReplayStream, ffi.LongLong)>>(
          'RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPort');
  late final _RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPort =
      _RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPortPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream, int)>();

  void RAPID_Core_CloudReplayStream_SetRetrieveErrorFunc(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    RAPID_Core_CloudReplayStream_RetrieveErrorFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_Core_CloudReplayStream_SetRetrieveErrorFunc(
      cloud_replay_stream,
      func,
      user_data,
    );
  }

  late final _RAPID_Core_CloudReplayStream_SetRetrieveErrorFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_CloudReplayStream,
            RAPID_Core_CloudReplayStream_RetrieveErrorFunc,
            ffi.Pointer<ffi.Void>,
          )>>('RAPID_Core_CloudReplayStream_SetRetrieveErrorFunc');
  late final _RAPID_Core_CloudReplayStream_SetRetrieveErrorFunc =
      _RAPID_Core_CloudReplayStream_SetRetrieveErrorFuncPtr.asFunction<
          void Function(
            RAPID_Core_CloudReplayStream,
            RAPID_Core_CloudReplayStream_RetrieveErrorFunc,
            ffi.Pointer<ffi.Void>,
          )>();

  void RAPID_Core_CloudReplayStream_EnableDownloadControl(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int enable,
  ) {
    return _RAPID_Core_CloudReplayStream_EnableDownloadControl(
      cloud_replay_stream,
      enable,
    );
  }

  late final _RAPID_Core_CloudReplayStream_EnableDownloadControlPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_Core_CloudReplayStream,
              ffi.Int)>>('RAPID_Core_CloudReplayStream_EnableDownloadControl');
  late final _RAPID_Core_CloudReplayStream_EnableDownloadControl =
      _RAPID_Core_CloudReplayStream_EnableDownloadControlPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream, int)>();

  void RAPID_Core_CloudReplayStream_SetFileNotFoundSendPort(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int port,
  ) {
    return _RAPID_Core_CloudReplayStream_SetFileNotFoundSendPort(
      cloud_replay_stream,
      port,
    );
  }

  late final _RAPID_Core_CloudReplayStream_SetFileNotFoundSendPortPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(RAPID_Core_CloudReplayStream, ffi.LongLong)>>(
      'RAPID_Core_CloudReplayStream_SetFileNotFoundSendPort');
  late final _RAPID_Core_CloudReplayStream_SetFileNotFoundSendPort =
      _RAPID_Core_CloudReplayStream_SetFileNotFoundSendPortPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream, int)>();

  void RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPort(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int port,
  ) {
    return _RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPort(
      cloud_replay_stream,
      port,
    );
  }

  late final _RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPortPtr =
      _lookup<
              ffi.NativeFunction<
                  ffi.Void Function(
                      RAPID_Core_CloudReplayStream, ffi.LongLong)>>(
          'RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPort');
  late final _RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPort =
      _RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPortPtr.asFunction<
          void Function(RAPID_Core_CloudReplayStream, int)>();

  RAPID_Core_StreamProvider RAPID_Core_CloudReplayStream_IndexedProvider(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    int index,
  ) {
    return _RAPID_Core_CloudReplayStream_IndexedProvider(
      cloud_replay_stream,
      index,
    );
  }

  late final _RAPID_Core_CloudReplayStream_IndexedProviderPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_StreamProvider Function(
            RAPID_Core_CloudReplayStream,
            ffi.UnsignedInt,
          )>>('RAPID_Core_CloudReplayStream_IndexedProvider');
  late final _RAPID_Core_CloudReplayStream_IndexedProvider =
      _RAPID_Core_CloudReplayStream_IndexedProviderPtr.asFunction<
          RAPID_Core_StreamProvider Function(
              RAPID_Core_CloudReplayStream, int)>();

  void RAPID_Core_Stream_EnableDebugging(int enable) {
    return _RAPID_Core_Stream_EnableDebugging(enable);
  }

  late final _RAPID_Core_Stream_EnableDebuggingPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int)>>(
    'RAPID_Core_Stream_EnableDebugging',
  );
  late final _RAPID_Core_Stream_EnableDebugging =
      _RAPID_Core_Stream_EnableDebuggingPtr.asFunction<void Function(int)>();

  RAPID_Core_RelayStream RAPID_Core_RelayStream_Create(
    ffi.Pointer<Utf8> device_id,
  ) {
    return _RAPID_Core_RelayStream_Create(device_id);
  }

  late final _RAPID_Core_RelayStream_CreatePtr = _lookup<
          ffi
          .NativeFunction<RAPID_Core_RelayStream Function(ffi.Pointer<Utf8>)>>(
      'RAPID_Core_RelayStream_Create');
  late final _RAPID_Core_RelayStream_Create = _RAPID_Core_RelayStream_CreatePtr
      .asFunction<RAPID_Core_RelayStream Function(ffi.Pointer<Utf8>)>();

  void RAPID_Core_RelayStream_Enqueue(
    RAPID_Core_RelayStream relay_stream,
    ffi.Pointer<RAPID_Core_StreamPacket> packet,
  ) {
    return _RAPID_Core_RelayStream_Enqueue(relay_stream, packet);
  }

  late final _RAPID_Core_RelayStream_EnqueuePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
            RAPID_Core_RelayStream,
            ffi.Pointer<RAPID_Core_StreamPacket>,
          )>>('RAPID_Core_RelayStream_Enqueue');
  late final _RAPID_Core_RelayStream_Enqueue =
      _RAPID_Core_RelayStream_EnqueuePtr.asFunction<
          void Function(
            RAPID_Core_RelayStream,
            ffi.Pointer<RAPID_Core_StreamPacket>,
          )>();

  void RAPID_Core_RelayStream_Release(RAPID_Core_RelayStream relay_stream) {
    return _RAPID_Core_RelayStream_Release(relay_stream);
  }

  late final _RAPID_Core_RelayStream_ReleasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_RelayStream)>>(
    'RAPID_Core_RelayStream_Release',
  );
  late final _RAPID_Core_RelayStream_Release =
      _RAPID_Core_RelayStream_ReleasePtr.asFunction<
          void Function(RAPID_Core_RelayStream)>();

  RAPID_Core_StreamProvider RAPID_Core_RelayStream_IndexedProvider(
    RAPID_Core_RelayStream relay_stream,
    int index,
  ) {
    return _RAPID_Core_RelayStream_IndexedProvider(relay_stream, index);
  }

  late final _RAPID_Core_RelayStream_IndexedProviderPtr = _lookup<
      ffi.NativeFunction<
          RAPID_Core_StreamProvider Function(
            RAPID_Core_RelayStream,
            ffi.UnsignedInt,
          )>>('RAPID_Core_RelayStream_IndexedProvider');
  late final _RAPID_Core_RelayStream_IndexedProvider =
      _RAPID_Core_RelayStream_IndexedProviderPtr.asFunction<
          RAPID_Core_StreamProvider Function(RAPID_Core_RelayStream, int)>();
}

class RAPID_Core_StreamPacket extends ffi.Opaque {}

class RAPID_Core_CloudReplayDownloadStartResult extends ffi.Struct {
  @ffi.Int()
  external int type;

  @ffi.Int()
  external int error_code;

  @ffi.UnsignedInt()
  external int requested_duration_seconds;

  @ffi.UnsignedInt()
  external int permitted_duration_seconds;
}

typedef RAPID_Core_LiveStream = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_StreamProvider = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_LocalReplayStream = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_CloudReplayStream = ffi.Pointer<ffi.Void>;
typedef RAPID_Core_CloudReplayStream_FileNotFoundFunc = ffi.Pointer<
    ffi.NativeFunction<RAPID_Core_CloudReplayStream_FileNotFoundFuncFunction>>;
typedef RAPID_Core_CloudReplayStream_FileNotFoundFuncFunction = ffi.Void
    Function(ffi.Int timestamp_s, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_Core_CloudReplayStream_FileNotFoundFuncFunction = void
    Function(int timestamp_s, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_Core_CloudReplayStream_DownloadCompleteFunc = ffi.Pointer<
    ffi
    .NativeFunction<RAPID_Core_CloudReplayStream_DownloadCompleteFuncFunction>>;
typedef RAPID_Core_CloudReplayStream_DownloadCompleteFuncFunction = ffi.Void
    Function(ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_Core_CloudReplayStream_DownloadCompleteFuncFunction = void
    Function(ffi.Pointer<ffi.Void> user_data);
typedef RAPID_Core_CloudReplayStream_RetrieveErrorFunc = ffi.Pointer<
    ffi.NativeFunction<RAPID_Core_CloudReplayStream_RetrieveErrorFuncFunction>>;
typedef RAPID_Core_CloudReplayStream_RetrieveErrorFuncFunction = ffi.Void
    Function(ffi.Int error_code, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_Core_CloudReplayStream_RetrieveErrorFuncFunction = void
    Function(int error_code, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_Core_RelayStream = ffi.Pointer<ffi.Void>;
