#ifndef FLUTTER_PLUGIN_RAPID_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_RAPID_KIT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>
#include <map>
#include "rapid_kit/rapid_kit_texture.h"


#include <memory>

namespace rapid_kit {

class RapidKitPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  RapidKitPlugin(flutter::TextureRegistrar* texture_registrar);

  virtual ~RapidKitPlugin();

  RapidKitPlugin(const RapidKitPlugin&) = delete;
  RapidKitPlugin& operator=(const RapidKitPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  flutter::TextureRegistrar* texture_registrar_;
  std::map<int64_t, RapidTexture*> textures_;
};

}  // namespace rapid_kit

#endif  // FLUTTER_PLUGIN_RAPID_KIT_PLUGIN_H_
