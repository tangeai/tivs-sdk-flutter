class VerificationCode {
  int? expiresInSeconds;
  bool? requireRobotCheck;
  bool? accountExist;

  VerificationCode({
    this.expiresInSeconds,
    this.requireRobotCheck,
    this.accountExist,
  });

  factory VerificationCode.fromJson(Map<String, dynamic> json) {
    return VerificationCode(
      expiresInSeconds: json['expires_in'] as int?,
      requireRobotCheck: json['robot_check'] as bool?,
      accountExist: json['account_exist'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'expires_in': expiresInSeconds,
      'robot_check': requireRobotCheck,
      'account_exist': accountExist,
    };
  }
}

class LoginRet {
  int? expiresInSeconds;
  String? accessToken;

  LoginRet({
    this.expiresInSeconds,
    this.accessToken,
  });

  factory LoginRet.fromJson(Map<String, dynamic> json) {
    return LoginRet(
      expiresInSeconds: json['expires_in'] as int?,
      accessToken: json['access_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'expires_in': expiresInSeconds,
      'access_token': accessToken,
    };
  }
}

class UserInfo {
  String? id;
  String? nickName;
  String? account;

  UserInfo({this.id, this.nickName, this.account});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['user_id'] as String?,
      nickName: json['nickname'] as String?,
      account: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': id,
      'nickname': nickName,
      'username': account,
    };
  }
}
