part of 'library.dart';

int rapidNativeCoreInitialize(
    String appId, String packageName, String language, bool debugging, int environment, bool httpLogging, String loggingCacheDirectory) {
  String platform = Platform.isIOS ? "ios" : "android";

  RapidNativeLogging().switchHttpLogging(httpLogging);

  Pointer<Utf8> appIdC = appId.toNativeUtf8();
  Pointer<Utf8> packageNameC = packageName.toNativeUtf8();
  Pointer<Utf8> platformC = platform.toNativeUtf8();
  Pointer<Utf8> languageC = language.toNativeUtf8();
  Pointer<Utf8> loggingCacheDirectoryC = loggingCacheDirectory.toNativeUtf8();

  int result = coreApiInitializeBinding.RAPID_Core_Initialize(
    appIdC,
    packageNameC,
    platformC,
    languageC,
    environment,
    loggingCacheDirectoryC,
    debugging ? 1 : 0,
  );

  calloc.free(appIdC);
  calloc.free(packageNameC);
  calloc.free(platformC);
  calloc.free(languageC);
  calloc.free(loggingCacheDirectoryC);

  return result;
}

String rapidNativeCoreVersionName() {
  final ret = coreApiInitializeBinding.RAPID_Core_VersionName();
  if (ret == nullptr || ret.address == 0) return "";
  final versionName = ret.toDartString();
  coreApiMemoryBinding.RAPID_Core_Memory_Toolbox_FreeCharPtr(ret);
  return versionName;
}

String rapidNativeCoreBuildId() {
  final ret = coreApiInitializeBinding.RAPID_Core_BuildId();
  if (ret == nullptr || ret.address == 0) return "";
  final buildId = ret.toDartString();
  coreApiMemoryBinding.RAPID_Core_Memory_Toolbox_FreeCharPtr(ret);
  return buildId;
}

String rapidNativeCoreCommitHash() {
  final ret = coreApiInitializeBinding.RAPID_Core_CommitHash();
  if (ret == nullptr || ret.address == 0) return "";
  final commitHash = ret.toDartString();
  coreApiMemoryBinding.RAPID_Core_Memory_Toolbox_FreeCharPtr(ret);
  return commitHash;
}
