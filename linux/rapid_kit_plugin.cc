#include "include/rapid_kit/rapid_kit_plugin.h"

#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>

#include <cstdint>
#include <cstring>
#include <map>
#include <string>
#include <vector>

#include "rapid/core/api/proto_type.h"
#include "rapid/media/api/chat.h"
#include "rapid/media/api/glue.h"
#include "rapid/sdl/api/common/sdl_vout_simple_callback.h"
#include "rapid/sdl/api/linux/sdl_ain_pulse_audio.h"
#include "rapid/sdl/api/linux/sdl_aout_pulse_audio.h"
#include "rapid_kit_ble.h"
#include "rapid_kit_texture.h"

#define RAPID_KIT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), rapid_kit_plugin_get_type(), RapidKitPlugin))

namespace {

struct TextureEntry {
  RapidTexture* texture;
};

FlMethodResponse* error_response(const char* code, const char* message) {
  return FL_METHOD_RESPONSE(fl_method_error_response_new(code, message, nullptr));
}

FlMethodResponse* success_response(FlValue* value = nullptr) {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(value));
}

FlMethodResponse* bool_response(bool value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  return success_response(result);
}

FlMethodResponse* int_response(int64_t value) {
  g_autoptr(FlValue) result = fl_value_new_int(value);
  return success_response(result);
}

FlMethodResponse* string_response(const char* value) {
  g_autoptr(FlValue) result = fl_value_new_string(value);
  return success_response(result);
}

FlValue* map_int_argument(FlMethodCall* method_call, const char* key) {
  FlValue* arguments = fl_method_call_get_args(method_call);
  if (!arguments || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) return nullptr;
  FlValue* value = fl_value_lookup_string(arguments, key);
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_INT ? value : nullptr;
}

FlValue* map_argument(FlMethodCall* method_call, const char* key, FlValueType type) {
  FlValue* arguments = fl_method_call_get_args(method_call);
  if (!arguments || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) return nullptr;
  FlValue* value = fl_value_lookup_string(arguments, key);
  return value && fl_value_get_type(value) == type ? value : nullptr;
}

std::vector<std::string> map_string_list_argument(FlMethodCall* method_call, const char* key) {
  std::vector<std::string> result;
  FlValue* value = map_argument(method_call, key, FL_VALUE_TYPE_LIST);
  if (!value) return result;
  for (size_t index = 0; index < fl_value_get_length(value); ++index) {
    FlValue* item = fl_value_get_list_value(value, index);
    if (item && fl_value_get_type(item) == FL_VALUE_TYPE_STRING) {
      result.emplace_back(fl_value_get_string(item));
    }
  }
  return result;
}

gchar* cache_directory(const char* child) {
  g_autofree gchar* directory =
      g_build_filename(g_get_user_cache_dir(), "rapid_kit", child, nullptr);
  if (g_mkdir_with_parents(directory, 0700) != 0) return g_strdup("");
  return g_strdup(directory);
}

gchar* capture_path() {
  g_autofree gchar* directory = cache_directory("capture");
  if (!directory || directory[0] == '\0') return g_strdup("");
  return g_strdup_printf("%s/rapid-%" G_GINT64_FORMAT, directory, g_get_real_time());
}

gchar* local_broadcast_address() {
  struct ifaddrs* interfaces = nullptr;
  if (getifaddrs(&interfaces) != 0) return g_strdup("");

  gchar* result = g_strdup("");
  for (struct ifaddrs* current = interfaces; current; current = current->ifa_next) {
    if (!current->ifa_addr || !current->ifa_netmask || current->ifa_addr->sa_family != AF_INET ||
        (current->ifa_flags & IFF_UP) == 0 || (current->ifa_flags & IFF_LOOPBACK) != 0) {
      continue;
    }

    const auto* address = reinterpret_cast<const sockaddr_in*>(current->ifa_addr);
    const auto* netmask = reinterpret_cast<const sockaddr_in*>(current->ifa_netmask);
    in_addr broadcast{};
    broadcast.s_addr = address->sin_addr.s_addr | ~netmask->sin_addr.s_addr;
    char buffer[INET_ADDRSTRLEN] = {};
    if (inet_ntop(AF_INET, &broadcast, buffer, sizeof(buffer))) {
      g_free(result);
      result = g_strdup(buffer);
      break;
    }
  }

  freeifaddrs(interfaces);
  return result;
}

void frame_callback(const RAPID_SDL_VoutOverlay* overlay, void* user_data) {
  rapid_texture_update_overlay(static_cast<RapidTexture*>(user_data), overlay);
}

}  // namespace

struct _RapidKitPlugin {
  GObject parent_instance;
  FlTextureRegistrar* texture_registrar;
  std::map<int64_t, TextureEntry>* textures;
  RapidKitBleContext* ble;
};

G_DEFINE_TYPE(RapidKitPlugin, rapid_kit_plugin, g_object_get_type())

static FlMethodResponse* attach_player_texture(RapidKitPlugin* self, FlMethodCall* method_call) {
  FlValue* player_value = map_int_argument(method_call, "playerPtr");
  if (!player_value) return error_response("BadArguments", "playerPtr is required");

  const int64_t player_address = fl_value_get_int(player_value);
  auto player = reinterpret_cast<RAPID_MediaPlayer>(static_cast<intptr_t>(player_address));
  if (!player) return error_response("BadArguments", "playerPtr is invalid");

  RapidTexture* texture = rapid_texture_new(self->texture_registrar);
  if (!fl_texture_registrar_register_texture(self->texture_registrar, FL_TEXTURE(texture))) {
    g_object_unref(texture);
    return error_response("TextureRegistrationFailed", "Failed to register texture");
  }

  RAPID_SDL_Vout* vout = RAPID_SDL_Vout_SimpleCallback_Create(frame_callback, texture);
  RAPID_SDL_Aout* aout = RAPID_SDL_Aout_CreateForPulseAudio();
  if (!vout || !aout) {
    if (vout) RAPID_SDL_Vout_Free(vout);
    if (aout) RAPID_SDL_AoutFree(aout);
    rapid_texture_detach(texture);
    g_object_unref(texture);
    return error_response("AudioVideoOutputFailed", "Failed to create Linux audio or video output");
  }

  RAPID_MediaPlayer_SetVout(player, vout);
  RAPID_MediaPlayer_SetAout(player, aout);
  const int64_t texture_id = fl_texture_get_id(FL_TEXTURE(texture));
  (*self->textures)[texture_id] = TextureEntry{texture};
  return int_response(texture_id);
}

static FlMethodResponse* detach_player_texture(RapidKitPlugin* self, FlMethodCall* method_call) {
  FlValue* texture_value = map_int_argument(method_call, "textureId");
  if (!texture_value) return error_response("BadArguments", "textureId is required");

  const int64_t texture_id = fl_value_get_int(texture_value);
  auto entry = self->textures->find(texture_id);
  if (entry != self->textures->end()) {
    rapid_texture_detach(entry->second.texture);
    g_object_unref(entry->second.texture);
    self->textures->erase(entry);
  }
  return success_response();
}

static FlMethodResponse* attach_media_chat(FlMethodCall* method_call) {
  FlValue* chat_value = map_int_argument(method_call, "mediaChatPtr");
  if (!chat_value) return error_response("BadArguments", "mediaChatPtr is required");

  const int64_t chat_address = fl_value_get_int(chat_value);
  auto chat = reinterpret_cast<RAPID_MediaChat>(static_cast<intptr_t>(chat_address));
  if (!chat || RAPID_MediaChat_IsStarted(chat) == RAPID_TRUE) {
    return error_response("AttachFailed", "MediaChat is invalid or already started");
  }

  RAPID_SDL_Ain* ain = RAPID_SDL_Ain_CreateForPulseAudio();
  if (!ain) return error_response("AttachFailed", "Failed to create PulseAudio input");
  RAPID_MediaChat_SetAin(chat, ain);
  return bool_response(true);
}

struct BleConnectTaskData {
  std::string address;
  std::vector<std::string> preferred_characteristics;
};

struct BleWriteTaskData {
  std::vector<uint8_t> data;
};

struct BleDisconnectTaskData {
  std::string address;
};

static void boolean_task_complete(GObject*, GAsyncResult* result, gpointer user_data) {
  auto* method_call = FL_METHOD_CALL(user_data);
  g_autoptr(GError) error = nullptr;
  const bool success = g_task_propagate_boolean(G_TASK(result), &error) == TRUE;
  if (error) g_warning("[RapidKitPlugin][boolean_task_complete] %s", error->message);
  g_autoptr(FlMethodResponse) response = bool_response(success);
  fl_method_call_respond(method_call, response, nullptr);
  g_object_unref(method_call);
}

static void void_task_complete(GObject*, GAsyncResult* result, gpointer user_data) {
  auto* method_call = FL_METHOD_CALL(user_data);
  g_autoptr(GError) error = nullptr;
  const bool success = g_task_propagate_boolean(G_TASK(result), &error) == TRUE;
  if (error) g_warning("[RapidKitPlugin][void_task_complete] %s", error->message);
  if (!success) g_warning("[RapidKitPlugin][void_task_complete] operation failed");
  g_autoptr(FlMethodResponse) response = success_response();
  fl_method_call_respond(method_call, response, nullptr);
  g_object_unref(method_call);
}

static void connect_bluetooth_task(GTask* task,
                                   gpointer source_object,
                                   gpointer task_data,
                                   GCancellable*) {
  auto* self = RAPID_KIT_PLUGIN(source_object);
  auto* data = static_cast<BleConnectTaskData*>(task_data);
  g_task_return_boolean(
      task, self->ble->connect(data->address, data->preferred_characteristics) ? TRUE : FALSE);
}

static void write_bluetooth_task(GTask* task,
                                 gpointer source_object,
                                 gpointer task_data,
                                 GCancellable*) {
  auto* self = RAPID_KIT_PLUGIN(source_object);
  auto* data = static_cast<BleWriteTaskData*>(task_data);
  g_task_return_boolean(task,
                        self->ble->write(data->data.data(), data->data.size()) ? TRUE : FALSE);
}

static void disconnect_bluetooth_task(GTask* task,
                                      gpointer source_object,
                                      gpointer task_data,
                                      GCancellable*) {
  auto* self = RAPID_KIT_PLUGIN(source_object);
  auto* data = static_cast<BleDisconnectTaskData*>(task_data);
  g_task_return_boolean(task, self->ble->disconnect(data->address) ? TRUE : FALSE);
}

static bool start_connect_bluetooth_task(RapidKitPlugin* self, FlMethodCall* method_call) {
  FlValue* address = map_argument(method_call, "mac", FL_VALUE_TYPE_STRING);
  if (!address) return false;

  auto* data = new BleConnectTaskData();
  data->address = fl_value_get_string(address);
  data->preferred_characteristics = map_string_list_argument(method_call, "characteristics");
  GTask* task =
      g_task_new(G_OBJECT(self), nullptr, boolean_task_complete, g_object_ref(method_call));
  g_task_set_task_data(
      task, data, [](gpointer value) { delete static_cast<BleConnectTaskData*>(value); });
  g_task_run_in_thread(task, connect_bluetooth_task);
  g_object_unref(task);
  return true;
}

static bool start_write_bluetooth_task(RapidKitPlugin* self, FlMethodCall* method_call) {
  FlValue* arguments = fl_method_call_get_args(method_call);
  if (!arguments || fl_value_get_type(arguments) != FL_VALUE_TYPE_UINT8_LIST) return false;

  const uint8_t* bytes = fl_value_get_uint8_list(arguments);
  const size_t length = fl_value_get_length(arguments);
  if (!bytes || length == 0) return false;

  auto* data = new BleWriteTaskData();
  data->data.assign(bytes, bytes + length);
  GTask* task =
      g_task_new(G_OBJECT(self), nullptr, boolean_task_complete, g_object_ref(method_call));
  g_task_set_task_data(
      task, data, [](gpointer value) { delete static_cast<BleWriteTaskData*>(value); });
  g_task_run_in_thread(task, write_bluetooth_task);
  g_object_unref(task);
  return true;
}

static bool start_disconnect_bluetooth_task(RapidKitPlugin* self, FlMethodCall* method_call) {
  FlValue* address = map_argument(method_call, "mac", FL_VALUE_TYPE_STRING);
  if (!address) return false;

  auto* data = new BleDisconnectTaskData();
  data->address = fl_value_get_string(address);
  GTask* task = g_task_new(G_OBJECT(self), nullptr, void_task_complete, g_object_ref(method_call));
  g_task_set_task_data(
      task, data, [](gpointer value) { delete static_cast<BleDisconnectTaskData*>(value); });
  g_task_run_in_thread(task, disconnect_bluetooth_task);
  g_object_unref(task);
  return true;
}

static FlMethodResponse* bluetooth_devices_response(RapidKitPlugin* self) {
  g_autoptr(FlValue) devices = fl_value_new_list();
  for (const auto& device : self->ble->nearby_devices()) {
    FlValue* value = fl_value_new_map();
    fl_value_set_string_take(value, "name", fl_value_new_string(device.name.c_str()));
    fl_value_set_string_take(value, "address", fl_value_new_string(device.address.c_str()));
    fl_value_append_take(devices, value);
  }
  return success_response(devices);
}

static void rapid_kit_plugin_handle_method_call(RapidKitPlugin* self, FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const char* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "attachPlayerTexture") == 0) {
    response = attach_player_texture(self, method_call);
  } else if (strcmp(method, "detachPlayerTexture") == 0) {
    response = detach_player_texture(self, method_call);
  } else if (strcmp(method, "attachMediaChat") == 0) {
    response = attach_media_chat(method_call);
  } else if (strcmp(method, "requireLoggingCacheDirectory") == 0) {
    g_autofree gchar* directory = cache_directory("log");
    response = string_response(directory);
  } else if (strcmp(method, "requireWriteableCachePath") == 0) {
    g_autofree gchar* path = capture_path();
    response = string_response(path);
  } else if (strcmp(method, "localNetworkBroadcastAddress") == 0) {
    g_autofree gchar* address = local_broadcast_address();
    response = string_response(address);
  } else if (strcmp(method, "currentWifi") == 0) {
    response = string_response("");
  } else if (strcmp(method, "requireMicrophone") == 0 ||
             strcmp(method, "requireLocationPermission") == 0 ||
             strcmp(method, "requestFileAccessPermission") == 0) {
    response = int_response(1);
  } else if (strcmp(method, "isMicrophoneRequired") == 0 ||
             strcmp(method, "isLocationPermissionRequired") == 0 ||
             strcmp(method, "isFileAccessPermissionGranted") == 0) {
    response = bool_response(true);
  } else if (strcmp(method, "isBluetoothPermissionGranted") == 0) {
    response = bool_response(self->ble->permission_granted());
  } else if (strcmp(method, "isBluetoothEnabled") == 0) {
    response = bool_response(self->ble->enabled());
  } else if (strcmp(method, "connectBluetoothDevice") == 0) {
    if (start_connect_bluetooth_task(self, method_call)) return;
    response = bool_response(false);
  } else if (strcmp(method, "writeBluetoothData") == 0) {
    if (start_write_bluetooth_task(self, method_call)) return;
    response = bool_response(false);
  } else if (strcmp(method, "launchWiFiSettings") == 0) {
    response = bool_response(false);
  } else if (strcmp(method, "acquireBluetoothPermission") == 0) {
    response = int_response(self->ble->acquire_permission());
  } else if (strcmp(method, "getBluetoothDevices") == 0) {
    response = bluetooth_devices_response(self);
  } else if (strcmp(method, "startBluetoothDiscovery") == 0) {
    self->ble->start_discovery();
    response = success_response();
  } else if (strcmp(method, "stopBluetoothDiscovery") == 0) {
    self->ble->stop_discovery();
    response = success_response();
  } else if (strcmp(method, "disconnectBluetoothDevice") == 0) {
    if (start_disconnect_bluetooth_task(self, method_call)) return;
    response = success_response();
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void rapid_kit_plugin_dispose(GObject* object) {
  auto* self = RAPID_KIT_PLUGIN(object);
  delete self->ble;
  self->ble = nullptr;
  if (self->textures) {
    for (const auto& entry : *self->textures) {
      rapid_texture_detach(entry.second.texture);
      g_object_unref(entry.second.texture);
    }
    delete self->textures;
    self->textures = nullptr;
  }
  g_clear_object(&self->texture_registrar);
  G_OBJECT_CLASS(rapid_kit_plugin_parent_class)->dispose(object);
}

static void rapid_kit_plugin_class_init(RapidKitPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = rapid_kit_plugin_dispose;
}

static void rapid_kit_plugin_init(RapidKitPlugin* self) {
  self->texture_registrar = nullptr;
  self->textures = new std::map<int64_t, TextureEntry>();
  self->ble = new RapidKitBleContext();
}

static void method_call_cb(FlMethodChannel*, FlMethodCall* method_call, gpointer user_data) {
  rapid_kit_plugin_handle_method_call(RAPID_KIT_PLUGIN(user_data), method_call);
}

void rapid_kit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  auto* plugin = RAPID_KIT_PLUGIN(g_object_new(rapid_kit_plugin_get_type(), nullptr));
  plugin->texture_registrar =
      FL_TEXTURE_REGISTRAR(g_object_ref(fl_plugin_registrar_get_texture_registrar(registrar)));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "com.tange.ai/rapid_kit/method.channel",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}
