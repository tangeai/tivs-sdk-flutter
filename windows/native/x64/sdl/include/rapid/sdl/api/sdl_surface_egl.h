#ifndef _RAPID_SDL_SURFACE_EGL_H_
#define _RAPID_SDL_SURFACE_EGL_H_

#include "rapid/core/api/proto_type.h"
#include "sdl_misc.h"
#include "sdl_surface.h"

#ifdef __cplusplus
extern "C" {
#endif

struct RAPID_SDL_Surface* RAPID_SDL_Surface_EGL_Create();
RAPID_Boolean RAPID_SDL_Surface_EGL_isValid(tgc_SDL_Surface* sdl_surface);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_SURFACE_EGL_H_
