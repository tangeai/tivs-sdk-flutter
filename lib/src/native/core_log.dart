part of 'library.dart';

class RapidNativeLogging {
  static final RapidNativeLogging _instance = RapidNativeLogging._internal();

  RapidNativeLogging._internal();
  factory RapidNativeLogging() {
    return _instance;
  }

  String upload() {
    final ptr = coreApiLogBinding.RAPID_Core_UploadLogging();
    if (ptr == nullptr || ptr.address == 0) return "native ptr error";
    String id = ptr.toDartString();
    coreApiMemoryBinding.RAPID_Core_Memory_Toolbox_FreeCharPtr(ptr);
    return id;
  }

  void log(int level, String tag, String message) {
    Pointer<Utf8> tagC = tag.toNativeUtf8();
    Pointer<Utf8> messageC = message.toNativeUtf8();
    coreApiLogBinding.RAPID_Core_LeveledLoggingPrint(level, tagC, messageC);
    calloc.free(tagC);
    calloc.free(messageC);
  }

  void switchHttpLogging(bool enable) {
    coreApiHttpBinding.RAPID_Core_Http_LoggingEnable(enable ? 1 : 0);
  }
}
