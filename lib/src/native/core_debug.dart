part of 'library.dart';

class RapidNativeDebuggingCode {
  static String create() {
    final ptr = coreApiDebugBinding.RAPID_Core_DebuggingCode_Create();
    if (ptr == nullptr || ptr.address == 0) return "";
    String id = ptr.toDartString();
    coreApiDebugBinding.RAPID_Core_DebuggingCode_Free(ptr);
    return id;
  }

  static bool apply(String code) {
    Pointer<Utf8> codeC = code.toNativeUtf8();
    Pointer<RAPID_Core_AuthResp> respPtr = coreApiDebugBinding.RAPID_Core_DebuggingCode_Apply(codeC);
    final result = respPtr.ref.success == 1;
    coreApiAuthBinding.RAPID_Core_AuthResp_Free(respPtr);
    calloc.free(codeC);
    return result;
  }
}
