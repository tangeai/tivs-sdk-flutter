part of 'library.dart';

enum PermissionType { microphone, camera, location, gallery, bluetooth }

enum PermissionState { unknown, granted, denied }

const _nativeGranted = 1;

class RuntimePermissions {
  static Future<PermissionState> requestAccess(PermissionType permission) async {
    if (PermissionType.microphone == permission) {
      return await _PlatformChannel.requireMicrophone() == _nativeGranted ? PermissionState.granted : PermissionState.denied;
    } else if (PermissionType.location == permission) {
      return await _PlatformChannel.requireLocationPermission() == _nativeGranted ? PermissionState.granted : PermissionState.denied;
    } else if (PermissionType.gallery == permission) {
      return await _PlatformChannel.requestFileAccessPermission() == _nativeGranted ? PermissionState.granted : PermissionState.denied;
    } else if (PermissionType.bluetooth == permission) {
      return await _PlatformChannel.acquireBluetoothPermission() == _nativeGranted ? PermissionState.granted : PermissionState.denied;
    } else {
      throw Exception('Unsupported permission');
    }
  }

  static Future<bool> accessGranted(PermissionType permission) async {
    if (permission == PermissionType.microphone) {
      return await _PlatformChannel.isMicrophoneRequired();
    } else if (permission == PermissionType.location) {
      return await _PlatformChannel.isLocationPermissionRequired();
    } else if (permission == PermissionType.gallery) {
      return await _PlatformChannel.isFileAccessPermissionGranted();
    } else if (permission == PermissionType.bluetooth) {
      return await _PlatformChannel.isBluetoothPermissionGranted();
    } else {
      return false;
    }
  }
}
