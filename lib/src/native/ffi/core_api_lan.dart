// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiLanBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiLanBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiLanBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  void RAPID_Core_LocalNetwork_SetBroadcastAddress(
    ffi.Pointer<Utf8> address,
  ) {
    return _RAPID_Core_LocalNetwork_SetBroadcastAddress(
      address,
    );
  }

  late final _RAPID_Core_LocalNetwork_SetBroadcastAddressPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>('RAPID_Core_LocalNetwork_SetBroadcastAddress');
  late final _RAPID_Core_LocalNetwork_SetBroadcastAddress =
      _RAPID_Core_LocalNetwork_SetBroadcastAddressPtr.asFunction<void Function(ffi.Pointer<Utf8>)>();

  RAPID_Core_LanScanner RAPID_Core_LanScanner_Create() {
    return _RAPID_Core_LanScanner_Create();
  }

  late final _RAPID_Core_LanScanner_CreatePtr = _lookup<ffi.NativeFunction<RAPID_Core_LanScanner Function()>>('RAPID_Core_LanScanner_Create');
  late final _RAPID_Core_LanScanner_Create = _RAPID_Core_LanScanner_CreatePtr.asFunction<RAPID_Core_LanScanner Function()>();

  void RAPID_Core_LanScanner_Destroy(
    RAPID_Core_LanScanner scanner,
  ) {
    return _RAPID_Core_LanScanner_Destroy(
      scanner,
    );
  }

  late final _RAPID_Core_LanScanner_DestroyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LanScanner)>>('RAPID_Core_LanScanner_Destroy');
  late final _RAPID_Core_LanScanner_Destroy = _RAPID_Core_LanScanner_DestroyPtr.asFunction<void Function(RAPID_Core_LanScanner)>();

  ffi.Pointer<Utf8> RAPID_Core_LanScanner_FoundDevices(
    RAPID_Core_LanScanner scanner,
  ) {
    return _RAPID_Core_LanScanner_FoundDevices(
      scanner,
    );
  }

  late final _RAPID_Core_LanScanner_FoundDevicesPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function(RAPID_Core_LanScanner)>>('RAPID_Core_LanScanner_FoundDevices');
  late final _RAPID_Core_LanScanner_FoundDevices =
      _RAPID_Core_LanScanner_FoundDevicesPtr.asFunction<ffi.Pointer<Utf8> Function(RAPID_Core_LanScanner)>();

  void RAPID_Core_LanScanner_Start(
    RAPID_Core_LanScanner scanner,
  ) {
    return _RAPID_Core_LanScanner_Start(
      scanner,
    );
  }

  late final _RAPID_Core_LanScanner_StartPtr = _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LanScanner)>>('RAPID_Core_LanScanner_Start');
  late final _RAPID_Core_LanScanner_Start = _RAPID_Core_LanScanner_StartPtr.asFunction<void Function(RAPID_Core_LanScanner)>();

  void RAPID_Core_LanScanner_Stop(
    RAPID_Core_LanScanner scanner,
  ) {
    return _RAPID_Core_LanScanner_Stop(
      scanner,
    );
  }

  late final _RAPID_Core_LanScanner_StopPtr = _lookup<ffi.NativeFunction<ffi.Void Function(RAPID_Core_LanScanner)>>('RAPID_Core_LanScanner_Stop');
  late final _RAPID_Core_LanScanner_Stop = _RAPID_Core_LanScanner_StopPtr.asFunction<void Function(RAPID_Core_LanScanner)>();
}

typedef RAPID_Core_LanScanner = ffi.Pointer<ffi.Void>;
