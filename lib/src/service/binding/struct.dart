enum BindingMode {
  modeScan,
  mode4G,
  modeLan,
  modeDevice,
  modeOther,
}

class BindedResp {
  String? deviceId;

  BindedResp({this.deviceId});

  factory BindedResp.fromJson(Map<String, dynamic> json) {
    return BindedResp(
      deviceId: json['device_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_id': deviceId,
    };
  }
}

class BindToken {
  String? token;
  int? expireIn;

  BindToken({this.token, this.expireIn});

  factory BindToken.fromJson(Map<String, dynamic> json) {
    return BindToken(
      token: json['token'] as String?,
      expireIn: json['expires_in'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'expires_in': expireIn,
    };
  }
}
