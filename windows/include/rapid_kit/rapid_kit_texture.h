#ifndef FLUTTER_PLUGIN_RAPID_KIT_TEXTURE_H_
#define FLUTTER_PLUGIN_RAPID_KIT_TEXTURE_H_

#include <flutter/method_channel.h>
#include <flutter/texture_registrar.h>
#include <flutter/plugin_registrar_windows.h>
#include <mutex>
#include <memory>
#include <vector>
#include "rapid/sdl/api/sdl_vout.h"

namespace rapid_kit {

class RapidTexture {
 public:
  RapidTexture(flutter::TextureRegistrar* texture_registrar);
  virtual ~RapidTexture();

  int64_t GetTextureId() const;
  void UpdateOverlay(const RAPID_SDL_VoutOverlay* overlay);
  void MarkDetached();

 private:
  FlutterDesktopPixelBuffer buffer_{};

  int64_t texture_id_;
  std::unique_ptr<flutter::TextureVariant> texture_variant_;
  flutter::TextureRegistrar* texture_registrar_ = nullptr;
  std::mutex mutex_;
  std::vector<uint8_t> pixel_buffer_;
  int width_;
  int height_;
  bool is_detached_ = false;
};

}  // namespace rapid_kit

#endif  // FLUTTER_PLUGIN_RAPID_KIT_TEXTURE_H_