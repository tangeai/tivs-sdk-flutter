import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../struct/resp.dart';
import '../../native/library.dart';

class HttpRequest {
  HttpRequest._();

  static Resp<String?> _requestInternal(_PostRequest request) {
    final nativeResp = rapidNativeHttpRequest(
        request.path, request.content, request.headers, request.method);
    if (nativeResp.success) {
      return Resp.success(nativeResp.data);
    } else {
      return Resp.error(nativeResp.code, nativeResp.message);
    }
  }

  static Future<Resp<String?>> post(String path, String content,
          [String headers = '{}']) =>
      compute(_requestInternal,
          _PostRequest(path, content, headers, RapidNativeHttpMethod.post));

  static Future<Resp<String?>> delete(String path, String content,
          [String headers = '{}']) =>
      compute(_requestInternal,
          _PostRequest(path, content, headers, RapidNativeHttpMethod.delete));

  static Future<Resp<String?>> patch(String path, String content,
          [String headers = '{}']) =>
      compute(_requestInternal,
          _PostRequest(path, content, headers, RapidNativeHttpMethod.patch));

  static Future<Resp<String?>> get(String path, String content,
          [String headers = '{}']) =>
      compute(_requestInternal,
          _PostRequest(path, content, headers, RapidNativeHttpMethod.get));
}

class _PostRequest {
  final String path;
  final String? content;
  final String headers;
  final RapidNativeHttpMethod method;

  _PostRequest(this.path, this.content, this.headers, this.method);
}
