class Ret {
  final bool success;
  final int? code;
  final String? message;

  Ret({required this.success, this.code, this.message});

  factory Ret.success() => Ret(success: true);

  factory Ret.error(int errorCode, String msg) => Ret(success: false, code: errorCode, message: msg);

  @override
  String toString() => 'Ret{success: $success, code: $code, message: $message}';
}

typedef OnResultListener = void Function(Ret);
