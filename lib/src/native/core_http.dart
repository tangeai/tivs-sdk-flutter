part of 'library.dart';

class RapidNativeHttpResponse {
  final bool success;
  final int code;
  final String message;
  final String data;

  RapidNativeHttpResponse(this.success, this.code, this.message, this.data);
}

enum RapidNativeHttpMethod { get, post, delete, patch }

RapidNativeHttpResponse rapidNativeHttpRequest(
    String path, String? param, String headers, RapidNativeHttpMethod method) {
  Pointer<Utf8> pathC = path.toNativeUtf8();
  Pointer<Utf8> paramC = param?.toNativeUtf8() ?? "".toNativeUtf8();
  Pointer<Utf8> headersC = headers.toNativeUtf8();

  int methodC = -1;
  if (method == RapidNativeHttpMethod.post) {
    methodC = RAPID_Core_HttpMethod.RAPID_Core_HttpMethod_POST;
  } else if (method == RapidNativeHttpMethod.get) {
    methodC = RAPID_Core_HttpMethod.RAPID_Core_HttpMethod_GET;
  } else if (method == RapidNativeHttpMethod.delete) {
    methodC = RAPID_Core_HttpMethod.RAPID_Core_HttpMethod_DELETE;
  } else if (method == RapidNativeHttpMethod.patch) {
    methodC = RAPID_Core_HttpMethod.RAPID_Core_HttpMethod_PATCH;
  }

  Pointer<RAPID_Core_HttpResp> respPtr =
      coreApiHttpBinding.RAPID_Core_HttpRequestWithHeaders(
          pathC, methodC, paramC, headersC);

  final response = RapidNativeHttpResponse(
    respPtr.ref.success == 1,
    respPtr.ref.code,
    respPtr.ref.message.address != 0 ? respPtr.ref.message.toDartString() : "",
    respPtr.ref.data.address != 0 ? respPtr.ref.data.toDartString() : "",
  );

  coreApiHttpBinding.RAPID_Core_HttpResp_Free(respPtr);

  calloc.free(pathC);
  calloc.free(paramC);
  calloc.free(headersC);

  return response;
}
