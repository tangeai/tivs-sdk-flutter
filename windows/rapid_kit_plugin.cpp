#include "rapid_kit/rapid_kit_plugin.h"
#include "rapid/core/api/log.h"
#include "rapid/media/api/glue.h"
#include "rapid/media/api/chat.h"
#include "rapid/sdl/api/sdl_vout.h"
#include "rapid/sdl/api/glue.h"
#include "rapid/sdl/api/windows/sdl_ain_wasapi.h"


// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#define TAG "RAPID_FLUTTER_PLUGIN"

void FrameCallback(const RAPID_SDL_VoutOverlay* overlay, void* user_data) {
  if (!user_data || !overlay) return;
  auto* texture = static_cast<rapid_kit::RapidTexture*>(user_data);
  texture->UpdateOverlay(overlay);
}

int AttachMediaChatAin(int64_t mediaChatPtr) {
  RAPID_MediaChat opaque_media_chat =
      reinterpret_cast<RAPID_MediaChat>(static_cast<intptr_t>(mediaChatPtr));
  if (!opaque_media_chat) {
    RAPID_LOGE(TAG, "[AttachMediaChatAin] invalid mediaChatPtr");
    return RAPID_FALSE;
  }

  if (RAPID_MediaChat_IsStarted(opaque_media_chat) == RAPID_TRUE) {
    RAPID_LOGE(TAG, "[AttachMediaChatAin] MediaChat already started");
    return RAPID_FALSE;
  }

  RAPID_SDL_Ain* opaque_ain = RAPID_SDL_Ain_CreateForWASAPI();
  if (!opaque_ain) {
    RAPID_LOGE(TAG, "[AttachMediaChatAin] CreateForWASAPI failed");
    return RAPID_FALSE;
  }

  RAPID_MediaChat_SetAin(opaque_media_chat, static_cast<void*>(opaque_ain));
  RAPID_LOGI(TAG, "[AttachMediaChatAin] ok");
  return RAPID_TRUE;
}

namespace rapid_kit {

// static
void RapidKitPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.tange.ai/rapid_kit/method.channel",
          &flutter::StandardMethodCodec::GetInstance());

  auto texture_registrar = registrar->texture_registrar();
  auto plugin = std::make_unique<RapidKitPlugin>(texture_registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

RapidKitPlugin::RapidKitPlugin(flutter::TextureRegistrar *texture_registrar)
    : texture_registrar_(texture_registrar) {}

RapidKitPlugin::~RapidKitPlugin() {}

void RapidKitPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("attachPlayerTexture") == 0) {

    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("Bad Arguments", "Expected argument map.");
      return;
    }

    auto playerPtr_it = args->find(flutter::EncodableValue("playerPtr"));
    if (playerPtr_it == args->end()) {
      result->Error("Bad Arguments", "playerPtr key not found.");
      return;
    }

    int64_t playerPtr = std::get<int64_t>(playerPtr_it->second);



    RapidTexture* texture = new RapidTexture(texture_registrar_);

    int64_t textureId = texture->GetTextureId();
    textures_[textureId] = texture;

    RAPID_MediaPlayer media_player = reinterpret_cast<RAPID_MediaPlayer>(static_cast<intptr_t>(playerPtr));

    RAPID_SDL_Vout* opaque_vout = RAPID_SDL_Vout_SimpleCallback_Create(FrameCallback, texture);
    void *_vout = static_cast<void *>(opaque_vout);
    RAPID_MediaPlayer_SetVout(media_player, _vout);

    RAPID_SDL_Aout* _opaque_aout = RAPID_SDL_Aout_CreateForWaveOut();
    void *_aout = static_cast<void *>(_opaque_aout);
    RAPID_MediaPlayer_SetAout(media_player, _aout);

    result->Success(flutter::EncodableValue(textureId));
  } else if (method_call.method_name().compare("attachMediaChat") == 0) {
    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("Bad Arguments", "Expected argument map.");
      return;
    }

    auto mediaChatPtr_it = args->find(flutter::EncodableValue("mediaChatPtr"));
    if (mediaChatPtr_it == args->end()) {
      result->Error("Bad Arguments", "mediaChatPtr key not found.");
      return;
    }

    int64_t mediaChatPtr = std::get<int64_t>(mediaChatPtr_it->second);
    const int rc = AttachMediaChatAin(mediaChatPtr);
    if (rc == RAPID_TRUE) {
      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error("AttachFailed", "Failed to attach WASAPI Ain to MediaChat.");
    }
  } else if (method_call.method_name().compare("detachPlayerTexture") == 0) {
    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("Bad Arguments", "Expected argument map.");
      return;
    }

    auto textureId_it = args->find(flutter::EncodableValue("textureId"));
    if (textureId_it == args->end()) {
      result->Error("Bad Arguments", "textureId key not found.");
      return;
    }

    int64_t textureId = std::get<int64_t>(textureId_it->second);

    auto texture = textures_[textureId];
    if (texture) {
      texture->MarkDetached();
      delete texture;
      textures_.erase(textureId);
    }

  } else {
    result->NotImplemented();
  }
}

}  // namespace rapid_kit
