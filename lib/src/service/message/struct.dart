class SendByAppRequest {
  final String? id;
  final String topic;
  final String data;

  SendByAppRequest({this.id, required this.topic, required this.data});

  Map<String, dynamic> toJson() {
    final params = <String, dynamic>{
      'topic': topic,
      'data': data,
    };

    if (id != null) {
      params['id'] = id;
    }

    return params;
  }
}
class SendByAppResp {
  final String? id;

  SendByAppResp({this.id});

  factory SendByAppResp.fromJson(Map<String, dynamic> json) {
    return SendByAppResp(id: json['id'] as String?);
  }
}
