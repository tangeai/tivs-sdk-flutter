import 'dart:convert';
import '../../toolbox/logging.dart';

const String _tag = "FirmwareStruct";

class CurrentVersion {
  String? id;
  String? version;
  int? sdkVersion;

  CurrentVersion({this.id, this.version, this.sdkVersion});

  factory CurrentVersion.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CurrentVersion(
        id: json['model_id'] as String?,
        version: json['version'] as String?,
        sdkVersion: json['sdkver'] as int?,
      );
    } catch (e) {
      Logging.e(_tag, 'Error parsing JSON: $e');
      return CurrentVersion();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'model_id': id,
      'version': version,
      'sdkver': sdkVersion,
    };
  }

  @override
  String toString() {
    return 'CurrentVersion{id: $id, version: $version, sdkVersion: $sdkVersion}';
  }
}

class AvailableVersion {
  String? version;
  String? description;

  AvailableVersion({this.version, this.description});

  factory AvailableVersion.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AvailableVersion(
        version: json['version'] as String?,
        description: json['content'] as String?,
      );
    } catch (e) {
      Logging.e(_tag, 'Error parsing JSON: $e');
      return AvailableVersion();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'content': description,
    };
  }

  @override
  String toString() {
    return 'AvailableVersion{version: $version, description: $description}';
  }
}

class FirmwareVersion {
  CurrentVersion? current;
  AvailableVersion? available;

  FirmwareVersion({this.current, this.available});

  factory FirmwareVersion.fromJson(Map<String, dynamic> json) {
    try {
      final firmwareVersion = FirmwareVersion(
        current: json['current_version'] == null ? null : CurrentVersion.fromJson(jsonEncode(json['current_version'])),
        available: json['target_version'] == null ? null : AvailableVersion.fromJson(jsonEncode(json['target_version'])),
      );
      if (firmwareVersion.available?.version == null || firmwareVersion.available?.version?.isEmpty == true) {
        firmwareVersion.available = null;
      }
      return firmwareVersion;
    } catch (e) {
      Logging.e(_tag, 'Error parsing JSON: $e');
      return FirmwareVersion();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'current_version': current?.toJson(),
      'target_version': available?.toJson(),
    };
  }

  @override
  String toString() {
    return 'FirmwareVersion{current: $current, available: $available}';
  }
}

class DeviceUpgradeStatus {
  int? status;
  String? description;
  String? currentVersion;
  int? upgradeTime;
  int? progress;

  DeviceUpgradeStatus({this.status, this.description, this.currentVersion, this.upgradeTime, this.progress});

  factory DeviceUpgradeStatus.fromJson(Map<String, dynamic> json) {
    try {
      return DeviceUpgradeStatus(
        status: json['status'] as int?,
        description: json['description'] as String?,
        currentVersion: json['version'] as String?,
        upgradeTime: json['upgrade_time'] as int?,
        progress: json['progress'] as int?,
      );
    } catch (e) {
      Logging.e(_tag, 'Error parsing JSON: $e');
      return DeviceUpgradeStatus();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      'description': description,
      'version': currentVersion,
      'upgrade_time': upgradeTime,
      'progress': progress,
    };
  }

  @override
  String toString() {
    return 'DeviceUpgradeStatus{status: $status, description: $description, currentVersion: $currentVersion, upgradeTime: $upgradeTime, progress: $progress}';
  }
}
