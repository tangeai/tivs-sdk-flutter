import 'dart:convert';

const int cloudRecordIndexErrorNoRecord = -100;

class CloudRecordIndexPacket {
  List<CloudRecordIndex> list;
  int total;

  CloudRecordIndexPacket({required this.list, required this.total});

  factory CloudRecordIndexPacket.fromJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is List<dynamic>) {
      final list = decoded.map(_recordFromJson).toList();
      return CloudRecordIndexPacket(list: list, total: list.length);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected an object response');
    }

    final dynamic items = decoded['items'];
    if (items != null && items is! List<dynamic>) {
      throw const FormatException('Expected items to be a list');
    }
    final list =
        (items as List<dynamic>? ?? <dynamic>[]).map(_recordFromJson).toList();
    final dynamic total = decoded['total'];
    if (total != null && total is! num) {
      throw const FormatException('Expected total to be a number');
    }
    return CloudRecordIndexPacket(
        list: list, total: (total as num?)?.toInt() ?? list.length);
  }

  static CloudRecordIndex _recordFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a record object');
    }
    return CloudRecordIndex.fromJson(value);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': list.map((i) => i.toJson()).toList(),
      'total': total,
    };
  }
}

class CloudRecordIndex {
  final int startTimestampSecond;
  final int endTimestampSecond;
  final int durationSecond;
  final String storageId;
  final String tag;
  final List<String> files;

  CloudRecordIndex({
    required this.startTimestampSecond,
    required int endTimestampSecond,
    int? durationSecond,
    required this.storageId,
    this.tag = "",
    this.files = const [],
  })  : endTimestampSecond = endTimestampSecond > startTimestampSecond
            ? endTimestampSecond
            : startTimestampSecond + 30,
        durationSecond = endTimestampSecond > startTimestampSecond
            ? durationSecond ?? endTimestampSecond - startTimestampSecond
            : 30;

  /// Whether this recording entry represents timelapse playback.
  /// Per-frame video flags are handled by the native playback pipeline.
  bool get isTimelapse => tag == "timelapse" && files.isNotEmpty;
  int get startTimestampInMs =>
      startTimestampSecond * Duration.millisecondsPerSecond;
  int get endTimestampInMs =>
      endTimestampSecond * Duration.millisecondsPerSecond;
  int get durationInMs => durationSecond * Duration.millisecondsPerSecond;

  factory CloudRecordIndex.fromJson(Map<String, dynamic> json) {
    final start = (json['start_time'] as num?)?.toInt() ?? 0;
    final end = (json['end_time'] as num?)?.toInt() ?? 0;
    final dynamic filesValue = json['files'];
    if (filesValue != null && filesValue is! List<dynamic>) {
      throw const FormatException('Expected files to be a list');
    }
    final filesJson = filesValue as List<dynamic>? ?? <dynamic>[];
    return CloudRecordIndex(
      startTimestampSecond: start,
      endTimestampSecond: end,
      storageId: json['ossid'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      files: filesJson.whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start_time': startTimestampSecond,
      'end_time': endTimestampSecond,
      'ossid': storageId,
      'tag': tag,
      'files': files,
    };
  }
}
