part of 'library.dart';

class RapidNativeLanScan {
  Pointer<Void>? _ptr;
  bool _started = false;
  RapidNativeLanScan();

  void start() {
    if (_started) return;
    _started = true;

    _destroy();
    _ptr = coreApiLanBinding.RAPID_Core_LanScanner_Create();
    if (_ptr != null && _ptr != nullptr) {
      coreApiLanBinding.RAPID_Core_LanScanner_Start(_ptr!);
    }
  }

  void stop() {
    if (!_started) return;
    _started = false;

    if (_ptr != null && _ptr != nullptr) {
      coreApiLanBinding.RAPID_Core_LanScanner_Stop(_ptr!);
    }
    _destroy();
  }

  List<String> foundDevices() {
    if (_ptr == null || _ptr == nullptr) return [];
    Pointer<Utf8> ptr = coreApiLanBinding.RAPID_Core_LanScanner_FoundDevices(_ptr!);
    if (ptr == nullptr || ptr.address == 0) return [];
    String deviceString = ptr.toDartString();
    coreApiMemoryBinding.RAPID_Core_Memory_Toolbox_FreeCharPtr(ptr);
    List<String> parsed = deviceString.isNotEmpty ? deviceString.split(" ") : [];
    final list = parsed.where((element) => element.isNotEmpty).toList();
    return list;
  }

  void _destroy() {
    if (_ptr != null && _ptr != nullptr) {
      coreApiLanBinding.RAPID_Core_LanScanner_Destroy(_ptr!);
      _ptr = null;
    }
  }
}
