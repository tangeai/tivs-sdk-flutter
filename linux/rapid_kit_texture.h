#ifndef FLUTTER_PLUGIN_RAPID_KIT_TEXTURE_H_
#define FLUTTER_PLUGIN_RAPID_KIT_TEXTURE_H_

#include <flutter_linux/flutter_linux.h>

#include "rapid/sdl/api/sdl_vout.h"

G_DECLARE_FINAL_TYPE(RapidTexture, rapid_texture, RAPID, TEXTURE, FlPixelBufferTexture)

RapidTexture* rapid_texture_new(FlTextureRegistrar* registrar);
void rapid_texture_update_overlay(RapidTexture* texture, const RAPID_SDL_VoutOverlay* overlay);
void rapid_texture_detach(RapidTexture* texture);

#endif  // FLUTTER_PLUGIN_RAPID_KIT_TEXTURE_H_
