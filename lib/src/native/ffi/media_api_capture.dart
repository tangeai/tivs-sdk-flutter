// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class MediaApiCaptureBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  MediaApiCaptureBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  MediaApiCaptureBinding.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  RAPID_MediaCapture RAPID_MediaCapture_Create() {
    return _RAPID_MediaCapture_Create();
  }

  late final _RAPID_MediaCapture_CreatePtr =
      _lookup<ffi.NativeFunction<RAPID_MediaCapture Function()>>(
          'RAPID_MediaCapture_Create');
  late final _RAPID_MediaCapture_Create =
      _RAPID_MediaCapture_CreatePtr.asFunction<RAPID_MediaCapture Function()>();

  void RAPID_MediaCapture_Destroy(
    RAPID_MediaCapture capture,
  ) {
    return _RAPID_MediaCapture_Destroy(
      capture,
    );
  }

  late final _RAPID_MediaCapture_DestroyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaCapture)>>(
          'RAPID_MediaCapture_Destroy');
  late final _RAPID_MediaCapture_Destroy = _RAPID_MediaCapture_DestroyPtr
      .asFunction<void Function(RAPID_MediaCapture)>();

  void RAPID_MediaCapture_Prepare(
    RAPID_MediaCapture capture,
    ffi.Pointer<ffi.Void> provider,
  ) {
    return _RAPID_MediaCapture_Prepare(
      capture,
      provider,
    );
  }

  late final _RAPID_MediaCapture_PreparePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaCapture,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaCapture_Prepare');
  late final _RAPID_MediaCapture_Prepare = _RAPID_MediaCapture_PreparePtr
      .asFunction<void Function(RAPID_MediaCapture, ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaCapture_SetTimeline(
    RAPID_MediaCapture capture,
    int start_utc_ms,
    int end_utc_ms,
  ) {
    return _RAPID_MediaCapture_SetTimeline(
      capture,
      start_utc_ms,
      end_utc_ms,
    );
  }

  late final _RAPID_MediaCapture_SetTimelinePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaCapture, ffi.Int64,
              ffi.Int64)>>('RAPID_MediaCapture_SetTimeline');
  late final _RAPID_MediaCapture_SetTimeline =
      _RAPID_MediaCapture_SetTimelinePtr.asFunction<
          void Function(RAPID_MediaCapture, int, int)>();

  void RAPID_MediaCapture_Start(
    RAPID_MediaCapture capture,
    ffi.Pointer<Utf8> output_file_path,
  ) {
    return _RAPID_MediaCapture_Start(
      capture,
      output_file_path,
    );
  }

  late final _RAPID_MediaCapture_StartPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaCapture,
              ffi.Pointer<Utf8>)>>('RAPID_MediaCapture_Start');
  late final _RAPID_MediaCapture_Start = _RAPID_MediaCapture_StartPtr
      .asFunction<void Function(RAPID_MediaCapture, ffi.Pointer<Utf8>)>();

  void RAPID_MediaCapture_Stop(
    RAPID_MediaCapture capture,
  ) {
    return _RAPID_MediaCapture_Stop(
      capture,
    );
  }

  late final _RAPID_MediaCapture_StopPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_MediaCapture)>>(
          'RAPID_MediaCapture_Stop');
  late final _RAPID_MediaCapture_Stop = _RAPID_MediaCapture_StopPtr.asFunction<
      void Function(RAPID_MediaCapture)>();

  int RAPID_MediaCapture_GetUts(
    RAPID_MediaCapture capture,
  ) {
    return _RAPID_MediaCapture_GetUts(
      capture,
    );
  }

  late final _RAPID_MediaCapture_GetUtsPtr =
      _lookup<ffi.NativeFunction<ffi.LongLong Function(RAPID_MediaCapture)>>(
          'RAPID_MediaCapture_GetUts');
  late final _RAPID_MediaCapture_GetUts = _RAPID_MediaCapture_GetUtsPtr
      .asFunction<int Function(RAPID_MediaCapture)>();

  int RAPID_MediaCapture_CurrentState(
    RAPID_MediaCapture capture,
  ) {
    return _RAPID_MediaCapture_CurrentState(
      capture,
    );
  }

  late final _RAPID_MediaCapture_CurrentStatePtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(RAPID_MediaCapture)>>(
          'RAPID_MediaCapture_CurrentState');
  late final _RAPID_MediaCapture_CurrentState =
      _RAPID_MediaCapture_CurrentStatePtr.asFunction<
          int Function(RAPID_MediaCapture)>();

  void RAPID_MediaCapture_SetStateFunc(
    RAPID_MediaCapture capture,
    RAPID_MediaCapture_StateFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaCapture_SetStateFunc(
      capture,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaCapture_SetStateFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaCapture, RAPID_MediaCapture_StateFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaCapture_SetStateFunc');
  late final _RAPID_MediaCapture_SetStateFunc =
      _RAPID_MediaCapture_SetStateFuncPtr.asFunction<
          void Function(RAPID_MediaCapture, RAPID_MediaCapture_StateFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaCapture_SetUtsFunc(
    RAPID_MediaCapture capture,
    RAPID_MediaCapture_UtsFunc func,
    ffi.Pointer<ffi.Void> user_data,
  ) {
    return _RAPID_MediaCapture_SetUtsFunc(
      capture,
      func,
      user_data,
    );
  }

  late final _RAPID_MediaCapture_SetUtsFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(RAPID_MediaCapture, RAPID_MediaCapture_UtsFunc,
              ffi.Pointer<ffi.Void>)>>('RAPID_MediaCapture_SetUtsFunc');
  late final _RAPID_MediaCapture_SetUtsFunc =
      _RAPID_MediaCapture_SetUtsFuncPtr.asFunction<
          void Function(RAPID_MediaCapture, RAPID_MediaCapture_UtsFunc,
              ffi.Pointer<ffi.Void>)>();

  void RAPID_MediaCapture_SetStateSendPort(
    RAPID_MediaCapture capture,
    int port,
  ) {
    return _RAPID_MediaCapture_SetStateSendPort(
      capture,
      port,
    );
  }

  late final _RAPID_MediaCapture_SetStateSendPortPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_MediaCapture, ffi.LongLong)>>(
      'RAPID_MediaCapture_SetStateSendPort');
  late final _RAPID_MediaCapture_SetStateSendPort =
      _RAPID_MediaCapture_SetStateSendPortPtr.asFunction<
          void Function(RAPID_MediaCapture, int)>();

  void RAPID_MediaCapture_SetUtsSendPort(
    RAPID_MediaCapture capture,
    int port,
  ) {
    return _RAPID_MediaCapture_SetUtsSendPort(
      capture,
      port,
    );
  }

  late final _RAPID_MediaCapture_SetUtsSendPortPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(RAPID_MediaCapture, ffi.LongLong)>>(
      'RAPID_MediaCapture_SetUtsSendPort');
  late final _RAPID_MediaCapture_SetUtsSendPort =
      _RAPID_MediaCapture_SetUtsSendPortPtr.asFunction<
          void Function(RAPID_MediaCapture, int)>();
}

abstract class RAPID_MediaCaptureState {
  static const int RAPID_MEDIA_CAPTURE_STATE_UNKNOWN = 0;
  static const int RAPID_MEDIA_CAPTURE_STATE_STARTED = 1;
  static const int RAPID_MEDIA_CAPTURE_STATE_COMPLETED = 2;
  static const int RAPID_MEDIA_CAPTURE_STATE_ERROR = 3;
  static const int RAPID_MEDIA_CAPTURE_STATE_STOPPED = 4;
}

typedef RAPID_MediaCapture = ffi.Pointer<ffi.Void>;
typedef RAPID_MediaCapture_StateFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaCapture_StateFuncFunction>>;
typedef RAPID_MediaCapture_StateFuncFunction = ffi.Void Function(
    ffi.Int state, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaCapture_StateFuncFunction = void Function(
    int state, ffi.Pointer<ffi.Void> user_data);
typedef RAPID_MediaCapture_UtsFunc
    = ffi.Pointer<ffi.NativeFunction<RAPID_MediaCapture_UtsFuncFunction>>;
typedef RAPID_MediaCapture_UtsFuncFunction = ffi.Void Function(
    ffi.LongLong uts_ms, ffi.Pointer<ffi.Void> user_data);
typedef DartRAPID_MediaCapture_UtsFuncFunction = void Function(
    int uts_ms, ffi.Pointer<ffi.Void> user_data);
