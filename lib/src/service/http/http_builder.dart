import '../../struct/resp.dart';
import 'http_request.dart';
import 'dart:convert';
export 'dart:convert';
export '../../struct/resp.dart';
export '../../struct/ret.dart';

class RequestBuilder {
  String? _path;
  final Map<String, dynamic> _params = <String, dynamic>{};
  final Map<String, String> _headers = <String, String>{};

  RequestBuilder path(String path) {
    _path = path;
    return this;
  }

  RequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  RequestBuilder map(Map<String, dynamic> fullParams) {
    _params.addAll(fullParams);
    return this;
  }

  RequestBuilder param(String key, dynamic value) {
    _params[key] = value;
    return this;
  }

  Future<Resp<String?>> post() async {
    return HttpRequest.post(_path!, jsonEncode(_params), jsonEncode(_headers));
  }

  Future<Resp<String?>> patch() async {
    return HttpRequest.patch(_path!, jsonEncode(_params), jsonEncode(_headers));
  }

  Future<Resp<String?>> delete() async {
    return HttpRequest.delete(
        _path!, jsonEncode(_params), jsonEncode(_headers));
  }

  Future<Resp<String?>> get() async {
    return HttpRequest.get(_path!, jsonEncode(_params), jsonEncode(_headers));
  }
}

class Http {
  static RequestBuilder create() {
    return RequestBuilder();
  }
}
