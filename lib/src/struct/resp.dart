import 'ret.dart';

class Resp<T> {
  final bool success;
  final int? code;
  final String? message;
  final T? data;

  Resp({required this.success, this.code, this.message, this.data});
  factory Resp.success(T data) => Resp<T>(success: true, code: 0, data: data);
  factory Resp.error(int code, String msg, [T? data]) => Resp<T>(success: false, code: code, message: msg, data: data);
  Ret toRet() => success ? Ret.success() : Ret.error(code ?? -1, message ?? "Unknown Error");

  @override
  String toString() => 'Resp{success: $success, code: $code, message: $message, data: $data}';
}

typedef OnResponseListener<T> = void Function(Resp<T>);
