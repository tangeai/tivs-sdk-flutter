#include "rapid_kit_ble.h"

#include <gio/gio.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace {

static const char kBluezService[] = "org.bluez";
static const char kObjectManagerInterface[] = "org.freedesktop.DBus.ObjectManager";
static const char kAdapterInterface[] = "org.bluez.Adapter1";
static const char kDeviceInterface[] = "org.bluez.Device1";
static const char kGattServiceInterface[] = "org.bluez.GattService1";
static const char kGattCharacteristicInterface[] = "org.bluez.GattCharacteristic1";
static const char kBluetoothBaseUuidSuffix[] = "-0000-1000-8000-00805f9b34fb";
static const int kDbusTimeoutMilliseconds = 10000;
static const int kConnectTimeoutMilliseconds = 30000;
static const int kWriteTimeoutMilliseconds = 10000;
static const int kInitialRetryDelayMilliseconds = 50;
static const int kMaximumRetryDelayMilliseconds = 500;
static const size_t kWritePacketLength = 20;
static const int kPermissionGranted = 1;
static const int kPermissionDenied = 2;

struct CharacteristicCandidate {
  std::string path;
  std::string uuid;
  std::string service_uuid;
  int score;
  bool write_without_response;
};

bool remote_error_matches(const GError* error, const char* name) {
  if (!error || !g_dbus_error_is_remote_error(error)) return false;
  g_autofree gchar* remote_name = g_dbus_error_get_remote_error(error);
  return remote_name && strcmp(remote_name, name) == 0;
}

GVariant* call_bluez(GDBusConnection* connection,
                     const char* path,
                     const char* interface,
                     const char* method,
                     GVariant* parameters,
                     const GVariantType* reply_type,
                     int timeout_milliseconds,
                     GError** error) {
  return g_dbus_connection_call_sync(connection,
                                     kBluezService,
                                     path,
                                     interface,
                                     method,
                                     parameters,
                                     reply_type,
                                     G_DBUS_CALL_FLAGS_NONE,
                                     timeout_milliseconds,
                                     nullptr,
                                     error);
}

GVariant* get_managed_objects(GDBusConnection* connection, GError** error) {
  g_autoptr(GVariant) response = call_bluez(connection,
                                            "/",
                                            kObjectManagerInterface,
                                            "GetManagedObjects",
                                            nullptr,
                                            G_VARIANT_TYPE("(a{oa{sa{sv}}})"),
                                            kDbusTimeoutMilliseconds,
                                            error);
  return response ? g_variant_get_child_value(response, 0) : nullptr;
}

GVariant* lookup_interface(GVariant* interfaces, const char* interface) {
  return g_variant_lookup_value(interfaces, interface, G_VARIANT_TYPE("a{sv}"));
}

std::string string_property(GVariant* properties, const char* name) {
  const char* value = nullptr;
  return g_variant_lookup(properties, name, "&s", &value) && value ? value : "";
}

std::string object_path_property(GVariant* properties, const char* name) {
  const char* value = nullptr;
  return g_variant_lookup(properties, name, "&o", &value) && value ? value : "";
}

bool bool_property(GVariant* properties, const char* name) {
  gboolean value = FALSE;
  return g_variant_lookup(properties, name, "b", &value) && value == TRUE;
}

std::vector<std::string> string_array_property(GVariant* properties, const char* name) {
  std::vector<std::string> values;
  g_autoptr(GVariant) array = g_variant_lookup_value(properties, name, G_VARIANT_TYPE("as"));
  if (!array) return values;

  GVariantIter iterator;
  const char* value = nullptr;
  g_variant_iter_init(&iterator, array);
  while (g_variant_iter_next(&iterator, "&s", &value)) values.emplace_back(value);
  return values;
}

std::string normalize_uuid(const std::string& uuid) {
  std::string normalized = uuid;
  std::transform(normalized.begin(), normalized.end(), normalized.begin(), [](unsigned char value) {
    return static_cast<char>(std::tolower(value));
  });
  if (normalized.length() == 4) return "0000" + normalized + kBluetoothBaseUuidSuffix;
  if (normalized.length() == 8) return normalized + kBluetoothBaseUuidSuffix;
  return normalized;
}

bool is_sig_assigned_service_uuid(const std::string& uuid) {
  const std::string normalized = normalize_uuid(uuid);
  if (normalized.length() != 36 || normalized.rfind("0000", 0) != 0 ||
      normalized.compare(8, strlen(kBluetoothBaseUuidSuffix), kBluetoothBaseUuidSuffix) != 0) {
    return false;
  }

  char* end = nullptr;
  const long value = strtol(normalized.substr(4, 4).c_str(), &end, 16);
  if (!end || *end != '\0') return false;
  return (value >= 0x1800 && value <= 0x180a) || (value >= 0x180d && value <= 0x1816) ||
         (value >= 0x1818 && value <= 0x1829) || (value >= 0x183a && value <= 0x1840) ||
         (value >= 0x1843 && value <= 0x1860);
}

int characteristic_score(const std::vector<std::string>& flags) {
  bool writable = false;
  int score = 100;
  for (const auto& flag : flags) {
    writable = writable || flag == "write" || flag == "write-without-response";
    if (flag == "notify") score += 50;
    if (flag == "indicate") score += 40;
    if (flag == "read") score += 10;
  }
  return writable ? score : 0;
}

bool has_flag(const std::vector<std::string>& flags, const char* expected) {
  return std::find(flags.begin(), flags.end(), expected) != flags.end();
}

void log_dbus_error(const char* operation, const GError* error) {
  if (error) g_warning("[RapidKitBleContext][%s] %s", operation, error->message);
}

}  // namespace

class RapidKitBleContextImpl {
 public:
  RapidKitBleContextImpl() = default;

  ~RapidKitBleContextImpl() {
    if (_connection) g_object_unref(_connection);
  }

  bool permission_granted() {
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return false;
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) objects = get_managed_objects(connection, &error);
    if (!objects) log_dbus_error("permission_granted", error);
    return objects != nullptr;
  }

  bool enabled() {
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return false;
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) objects = get_managed_objects(connection, &error);
    if (!objects) {
      log_dbus_error("enabled", error);
      return false;
    }

    GVariantIter iterator;
    const char* path = nullptr;
    GVariant* interfaces = nullptr;
    g_variant_iter_init(&iterator, objects);
    while (g_variant_iter_next(&iterator, "{&o@a{sa{sv}}}", &path, &interfaces)) {
      g_autoptr(GVariant) owned_interfaces = interfaces;
      g_autoptr(GVariant) properties = lookup_interface(owned_interfaces, kAdapterInterface);
      if (properties && bool_property(properties, "Powered")) return true;
    }
    return false;
  }

  bool start_discovery() {
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return false;
    const std::string adapter_path = find_adapter_path(connection);
    if (adapter_path.empty()) return false;

    GVariantBuilder filter;
    g_variant_builder_init(&filter, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&filter, "{sv}", "Transport", g_variant_new_string("le"));
    g_autoptr(GError) filter_error = nullptr;
    g_autoptr(GVariant) filter_response = call_bluez(connection,
                                                     adapter_path.c_str(),
                                                     kAdapterInterface,
                                                     "SetDiscoveryFilter",
                                                     g_variant_new("(a{sv})", &filter),
                                                     G_VARIANT_TYPE("()"),
                                                     kDbusTimeoutMilliseconds,
                                                     &filter_error);
    if (!filter_response) log_dbus_error("set_discovery_filter", filter_error);

    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) response = call_bluez(connection,
                                              adapter_path.c_str(),
                                              kAdapterInterface,
                                              "StartDiscovery",
                                              nullptr,
                                              G_VARIANT_TYPE("()"),
                                              kDbusTimeoutMilliseconds,
                                              &error);
    if (response || remote_error_matches(error, "org.bluez.Error.InProgress")) return true;
    log_dbus_error("start_discovery", error);
    return false;
  }

  bool stop_discovery() {
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return false;
    const std::string adapter_path = find_adapter_path(connection);
    if (adapter_path.empty()) return false;

    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) response = call_bluez(connection,
                                              adapter_path.c_str(),
                                              kAdapterInterface,
                                              "StopDiscovery",
                                              nullptr,
                                              G_VARIANT_TYPE("()"),
                                              kDbusTimeoutMilliseconds,
                                              &error);
    if (response || remote_error_matches(error, "org.bluez.Error.NotReady")) return true;
    log_dbus_error("stop_discovery", error);
    return false;
  }

  std::vector<RapidKitBleDevice> nearby_devices() {
    std::vector<RapidKitBleDevice> result;
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return result;
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) objects = get_managed_objects(connection, &error);
    if (!objects) {
      log_dbus_error("nearby_devices", error);
      return result;
    }

    std::set<std::string> addresses;
    GVariantIter iterator;
    const char* path = nullptr;
    GVariant* interfaces = nullptr;
    g_variant_iter_init(&iterator, objects);
    while (g_variant_iter_next(&iterator, "{&o@a{sa{sv}}}", &path, &interfaces)) {
      g_autoptr(GVariant) owned_interfaces = interfaces;
      g_autoptr(GVariant) properties = lookup_interface(owned_interfaces, kDeviceInterface);
      if (!properties) continue;

      const std::string address = string_property(properties, "Address");
      std::string name = string_property(properties, "Name");
      if (name.empty()) name = string_property(properties, "Alias");
      if (address.empty() || name.empty() || !addresses.insert(address).second) continue;
      result.push_back({name, address});
    }
    std::sort(result.begin(), result.end(), [](const auto& lhs, const auto& rhs) {
      return lhs.address < rhs.address;
    });
    return result;
  }

  bool connect(const std::string& address,
               const std::vector<std::string>& preferred_characteristics) {
    std::lock_guard<std::mutex> operation_lock(_operation_mutex);
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return false;
    const std::string device_path = find_device_path(connection, address);
    if (device_path.empty()) return false;

    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) response = call_bluez(connection,
                                              device_path.c_str(),
                                              kDeviceInterface,
                                              "Connect",
                                              nullptr,
                                              G_VARIANT_TYPE("()"),
                                              kConnectTimeoutMilliseconds,
                                              &error);
    if (!response && !remote_error_matches(error, "org.bluez.Error.AlreadyConnected")) {
      log_dbus_error("connect", error);
      return false;
    }

    CharacteristicCandidate characteristic;
    if (!wait_for_characteristic(
            connection, device_path, preferred_characteristics, &characteristic)) {
      disconnect_device(connection, device_path);
      return false;
    }

    std::lock_guard<std::mutex> state_lock(_state_mutex);
    _device_path = device_path;
    _characteristic_path = characteristic.path;
    _write_without_response = characteristic.write_without_response;
    return true;
  }

  bool disconnect(const std::string& address) {
    std::lock_guard<std::mutex> operation_lock(_operation_mutex);
    g_autoptr(GDBusConnection) connection = require_connection();
    std::string device_path;
    {
      std::lock_guard<std::mutex> state_lock(_state_mutex);
      device_path = _device_path;
      clear_connected_state();
    }
    if (!connection) return device_path.empty();
    if (device_path.empty() && !address.empty())
      device_path = find_device_path(connection, address);
    if (device_path.empty()) return true;
    return disconnect_device(connection, device_path);
  }

  bool write(const uint8_t* data, size_t length) {
    if (!data || length == 0) return false;
    std::lock_guard<std::mutex> operation_lock(_operation_mutex);
    g_autoptr(GDBusConnection) connection = require_connection();
    if (!connection) return false;

    std::string characteristic_path;
    bool write_without_response = false;
    {
      std::lock_guard<std::mutex> state_lock(_state_mutex);
      characteristic_path = _characteristic_path;
      write_without_response = _write_without_response;
    }
    if (characteristic_path.empty()) return false;

    for (size_t offset = 0; offset < length; offset += kWritePacketLength) {
      const size_t packet_length = std::min(kWritePacketLength, length - offset);
      if (!write_packet(connection,
                        characteristic_path,
                        write_without_response,
                        data + offset,
                        packet_length)) {
        return false;
      }
    }
    return true;
  }

 private:
  GDBusConnection* require_connection() {
    std::lock_guard<std::mutex> state_lock(_state_mutex);
    if (_connection && !g_dbus_connection_is_closed(_connection)) {
      return G_DBUS_CONNECTION(g_object_ref(_connection));
    }
    g_clear_object(&_connection);

    g_autoptr(GError) error = nullptr;
    _connection = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (!_connection) {
      log_dbus_error("require_connection", error);
      return nullptr;
    }
    return G_DBUS_CONNECTION(g_object_ref(_connection));
  }

  std::string find_adapter_path(GDBusConnection* connection) {
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) objects = get_managed_objects(connection, &error);
    if (!objects) {
      log_dbus_error("find_adapter_path", error);
      return "";
    }

    GVariantIter iterator;
    const char* path = nullptr;
    GVariant* interfaces = nullptr;
    g_variant_iter_init(&iterator, objects);
    while (g_variant_iter_next(&iterator, "{&o@a{sa{sv}}}", &path, &interfaces)) {
      g_autoptr(GVariant) owned_interfaces = interfaces;
      g_autoptr(GVariant) properties = lookup_interface(owned_interfaces, kAdapterInterface);
      if (properties) return path;
    }
    return "";
  }

  std::string find_device_path(GDBusConnection* connection, const std::string& address) {
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) objects = get_managed_objects(connection, &error);
    if (!objects) {
      log_dbus_error("find_device_path", error);
      return "";
    }

    GVariantIter iterator;
    const char* path = nullptr;
    GVariant* interfaces = nullptr;
    g_variant_iter_init(&iterator, objects);
    while (g_variant_iter_next(&iterator, "{&o@a{sa{sv}}}", &path, &interfaces)) {
      g_autoptr(GVariant) owned_interfaces = interfaces;
      g_autoptr(GVariant) properties = lookup_interface(owned_interfaces, kDeviceInterface);
      if (!properties) continue;
      const std::string candidate = string_property(properties, "Address");
      if (g_ascii_strcasecmp(candidate.c_str(), address.c_str()) == 0) return path;
    }
    return "";
  }

  bool wait_for_characteristic(GDBusConnection* connection,
                               const std::string& device_path,
                               const std::vector<std::string>& preferred_characteristics,
                               CharacteristicCandidate* selected) {
    const gint64 deadline =
        g_get_monotonic_time() + kConnectTimeoutMilliseconds * G_TIME_SPAN_MILLISECOND;
    int delay_milliseconds = kInitialRetryDelayMilliseconds;
    while (g_get_monotonic_time() < deadline) {
      if (find_characteristic(connection, device_path, preferred_characteristics, selected)) {
        return true;
      }
      g_usleep(delay_milliseconds * G_TIME_SPAN_MILLISECOND);
      delay_milliseconds = std::min(delay_milliseconds * 2, kMaximumRetryDelayMilliseconds);
    }
    g_warning("[RapidKitBleContext][wait_for_characteristic] no writable characteristic");
    return false;
  }

  bool find_characteristic(GDBusConnection* connection,
                           const std::string& device_path,
                           const std::vector<std::string>& preferred_characteristics,
                           CharacteristicCandidate* selected) {
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) objects = get_managed_objects(connection, &error);
    if (!objects) return false;

    std::map<std::string, std::string> service_uuids;
    GVariantIter service_iterator;
    const char* path = nullptr;
    GVariant* interfaces = nullptr;
    g_variant_iter_init(&service_iterator, objects);
    while (g_variant_iter_next(&service_iterator, "{&o@a{sa{sv}}}", &path, &interfaces)) {
      g_autoptr(GVariant) owned_interfaces = interfaces;
      g_autoptr(GVariant) properties = lookup_interface(owned_interfaces, kGattServiceInterface);
      if (!properties || object_path_property(properties, "Device") != device_path) continue;
      service_uuids[path] = string_property(properties, "UUID");
    }

    std::set<std::string> preferred;
    for (const auto& uuid : preferred_characteristics) preferred.insert(normalize_uuid(uuid));
    CharacteristicCandidate preferred_candidate;
    CharacteristicCandidate automatic_candidate;
    bool has_preferred = false;
    bool has_automatic = false;

    GVariantIter characteristic_iterator;
    g_variant_iter_init(&characteristic_iterator, objects);
    while (g_variant_iter_next(&characteristic_iterator, "{&o@a{sa{sv}}}", &path, &interfaces)) {
      g_autoptr(GVariant) owned_interfaces = interfaces;
      g_autoptr(GVariant) properties =
          lookup_interface(owned_interfaces, kGattCharacteristicInterface);
      if (!properties) continue;

      const std::string service_path = object_path_property(properties, "Service");
      const auto service = service_uuids.find(service_path);
      if (service == service_uuids.end()) continue;
      const std::vector<std::string> flags = string_array_property(properties, "Flags");
      const int score = characteristic_score(flags);
      if (score == 0) continue;

      const std::string uuid = normalize_uuid(string_property(properties, "UUID"));
      const bool without_response =
          !has_flag(flags, "write") && has_flag(flags, "write-without-response");
      CharacteristicCandidate candidate{path, uuid, service->second, score, without_response};
      if (preferred.count(uuid) > 0 && (!has_preferred || score > preferred_candidate.score)) {
        preferred_candidate = candidate;
        has_preferred = true;
      }
      if (!is_sig_assigned_service_uuid(service->second) &&
          (!has_automatic || score > automatic_candidate.score)) {
        automatic_candidate = candidate;
        has_automatic = true;
      }
    }

    if (has_preferred) {
      *selected = preferred_candidate;
      return true;
    }
    if (has_automatic) {
      *selected = automatic_candidate;
      return true;
    }
    return false;
  }

  bool disconnect_device(GDBusConnection* connection, const std::string& device_path) {
    g_autoptr(GError) error = nullptr;
    g_autoptr(GVariant) response = call_bluez(connection,
                                              device_path.c_str(),
                                              kDeviceInterface,
                                              "Disconnect",
                                              nullptr,
                                              G_VARIANT_TYPE("()"),
                                              kDbusTimeoutMilliseconds,
                                              &error);
    if (response || remote_error_matches(error, "org.bluez.Error.NotConnected")) return true;
    log_dbus_error("disconnect", error);
    return false;
  }

  bool write_packet(GDBusConnection* connection,
                    const std::string& characteristic_path,
                    bool write_without_response,
                    const uint8_t* data,
                    size_t length) {
    const gint64 deadline =
        g_get_monotonic_time() + kWriteTimeoutMilliseconds * G_TIME_SPAN_MILLISECOND;
    int delay_milliseconds = kInitialRetryDelayMilliseconds;
    while (g_get_monotonic_time() < deadline) {
      GVariantBuilder value;
      g_variant_builder_init(&value, G_VARIANT_TYPE("ay"));
      for (size_t index = 0; index < length; ++index) {
        g_variant_builder_add(&value, "y", data[index]);
      }
      GVariantBuilder options;
      g_variant_builder_init(&options, G_VARIANT_TYPE("a{sv}"));
      g_variant_builder_add(&options,
                            "{sv}",
                            "type",
                            g_variant_new_string(write_without_response ? "command" : "request"));

      g_autoptr(GError) error = nullptr;
      g_autoptr(GVariant) response = call_bluez(connection,
                                                characteristic_path.c_str(),
                                                kGattCharacteristicInterface,
                                                "WriteValue",
                                                g_variant_new("(aya{sv})", &value, &options),
                                                G_VARIANT_TYPE("()"),
                                                kDbusTimeoutMilliseconds,
                                                &error);
      if (response) return true;
      if (!remote_error_matches(error, "org.bluez.Error.InProgress")) {
        log_dbus_error("write", error);
        return false;
      }
      g_usleep(delay_milliseconds * G_TIME_SPAN_MILLISECOND);
      delay_milliseconds = std::min(delay_milliseconds * 2, kMaximumRetryDelayMilliseconds);
    }
    return false;
  }

  void clear_connected_state() {
    _device_path.clear();
    _characteristic_path.clear();
    _write_without_response = false;
  }

  GDBusConnection* _connection = nullptr;
  std::mutex _state_mutex;
  std::mutex _operation_mutex;
  std::string _device_path;
  std::string _characteristic_path;
  bool _write_without_response = false;
};

RapidKitBleContext::RapidKitBleContext() : _impl(new RapidKitBleContextImpl()) {}

RapidKitBleContext::~RapidKitBleContext() { delete _impl; }

bool RapidKitBleContext::permission_granted() { return _impl->permission_granted(); }

int RapidKitBleContext::acquire_permission() {
  return permission_granted() ? kPermissionGranted : kPermissionDenied;
}

bool RapidKitBleContext::enabled() { return _impl->enabled(); }

bool RapidKitBleContext::start_discovery() { return _impl->start_discovery(); }

bool RapidKitBleContext::stop_discovery() { return _impl->stop_discovery(); }

std::vector<RapidKitBleDevice> RapidKitBleContext::nearby_devices() {
  return _impl->nearby_devices();
}

bool RapidKitBleContext::connect(const std::string& address,
                                 const std::vector<std::string>& preferred_characteristics) {
  return _impl->connect(address, preferred_characteristics);
}

bool RapidKitBleContext::disconnect(const std::string& address) {
  return _impl->disconnect(address);
}

bool RapidKitBleContext::write(const uint8_t* data, size_t length) {
  return _impl->write(data, length);
}
