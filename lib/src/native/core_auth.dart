part of 'library.dart';

class RapidNativeAuthenticateResponse {
  final int userId;
  final int issueAt;
  final int expiresIn;
  final bool success;
  final String message;
  final int code;

  RapidNativeAuthenticateResponse({
    required this.userId,
    required this.issueAt,
    required this.expiresIn,
    required this.success,
    required this.message,
    required this.code,
  });
}

RapidNativeAuthenticateResponse rapidNativeAuthenticate(String accessToken) {
  Pointer<Utf8> accessTokenC = accessToken.toNativeUtf8();

  Pointer<RAPID_Core_AuthResp> respPtr = coreApiAuthBinding.RAPID_Core_Authenticate(accessTokenC);

  final response = RapidNativeAuthenticateResponse(
    userId: respPtr.ref.user_id,
    issueAt: respPtr.ref.issue_at,
    expiresIn: respPtr.ref.expires_in,
    success: respPtr.ref.success == 1,
    message: respPtr.ref.message.address != 0 ? respPtr.ref.message.toDartString() : "",
    code: respPtr.ref.code,
  );

  coreApiAuthBinding.RAPID_Core_AuthResp_Free(respPtr);

  calloc.free(accessTokenC);

  return response;
}
