#ifndef FLUTTER_PLUGIN_RAPID_KIT_BLE_H_
#define FLUTTER_PLUGIN_RAPID_KIT_BLE_H_

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

struct RapidKitBleDevice {
  std::string name;
  std::string address;
};

class RapidKitBleContextImpl;

class RapidKitBleContext {
 public:
  RapidKitBleContext();
  ~RapidKitBleContext();

  bool permission_granted();
  int acquire_permission();
  bool enabled();
  bool start_discovery();
  bool stop_discovery();
  std::vector<RapidKitBleDevice> nearby_devices();
  bool connect(const std::string& address,
               const std::vector<std::string>& preferred_characteristics);
  bool disconnect(const std::string& address);
  bool write(const uint8_t* data, size_t length);

 private:
  RapidKitBleContextImpl* _impl;
};

#endif  // FLUTTER_PLUGIN_RAPID_KIT_BLE_H_
