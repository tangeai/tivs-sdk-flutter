#include "include/rapid_kit/rapid_kit_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "rapid_kit/rapid_kit_plugin.h"

void RapidKitPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  rapid_kit::RapidKitPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
