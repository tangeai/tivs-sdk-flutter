// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names, lines_longer_than_80_chars
part of 'library.dart';

class CoreApiInitializeBinding {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  CoreApiInitializeBinding(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  CoreApiInitializeBinding.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup) : _lookup = lookup;

  int RAPID_Core_Initialize(
    ffi.Pointer<Utf8> app_id,
    ffi.Pointer<Utf8> package_name,
    ffi.Pointer<Utf8> platform,
    ffi.Pointer<Utf8> language,
    int environment,
    ffi.Pointer<Utf8> logging_cache_directory,
    int console_logging,
  ) {
    return _RAPID_Core_Initialize(
      app_id,
      package_name,
      platform,
      language,
      environment,
      logging_cache_directory,
      console_logging,
    );
  }

  late final _RAPID_Core_InitializePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Int, ffi.Pointer<Utf8>,
              ffi.Int)>>('RAPID_Core_Initialize');
  late final _RAPID_Core_Initialize = _RAPID_Core_InitializePtr.asFunction<
      int Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>, int)>();

  ffi.Pointer<Utf8> RAPID_Core_VersionName() {
    return _RAPID_Core_VersionName();
  }

  late final _RAPID_Core_VersionNamePtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_VersionName');
  late final _RAPID_Core_VersionName = _RAPID_Core_VersionNamePtr.asFunction<ffi.Pointer<Utf8> Function()>();

  ffi.Pointer<Utf8> RAPID_Core_BuildId() {
    return _RAPID_Core_BuildId();
  }

  late final _RAPID_Core_BuildIdPtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_BuildId');
  late final _RAPID_Core_BuildId = _RAPID_Core_BuildIdPtr.asFunction<ffi.Pointer<Utf8> Function()>();

  ffi.Pointer<Utf8> RAPID_Core_CommitHash() {
    return _RAPID_Core_CommitHash();
  }

  late final _RAPID_Core_CommitHashPtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_CommitHash');
  late final _RAPID_Core_CommitHash = _RAPID_Core_CommitHashPtr.asFunction<ffi.Pointer<Utf8> Function()>();

  ffi.Pointer<Utf8> RAPID_Core_AppId() {
    return _RAPID_Core_AppId();
  }

  late final _RAPID_Core_AppIdPtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_AppId');
  late final _RAPID_Core_AppId = _RAPID_Core_AppIdPtr.asFunction<ffi.Pointer<Utf8> Function()>();

  ffi.Pointer<Utf8> RAPID_Core_PackageName() {
    return _RAPID_Core_PackageName();
  }

  late final _RAPID_Core_PackageNamePtr = _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>('RAPID_Core_PackageName');
  late final _RAPID_Core_PackageName = _RAPID_Core_PackageNamePtr.asFunction<ffi.Pointer<Utf8> Function()>();
}
