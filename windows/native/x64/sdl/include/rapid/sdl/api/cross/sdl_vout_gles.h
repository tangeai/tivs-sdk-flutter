#ifndef _RAPID_SDL_VOUT_GLES_H_
#define _RAPID_SDL_VOUT_GLES_H_

#include "rapid/sdl/api/sdl_surface.h"
#include "rapid/sdl/api/sdl_vout.h"

#ifdef __cplusplus
extern "C" {
#endif

RAPID_SDL_Vout* RAPID_SDL_Vout_CreateGLES(RAPID_SDL_Surface* surface);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_VOUT_GLES_H_