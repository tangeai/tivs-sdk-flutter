#ifndef _RAPID_SDL_SURFACE_OHOS_H_
#define _RAPID_SDL_SURFACE_OHOS_H_

#include "rapid/sdl/api/sdl_surface.h"

#ifdef __cplusplus
extern "C" {
#endif

struct RAPID_SDL_Surface *RAPID_SDL_Surface_OHOS_Create(void *native_window,
                                                        int surface_width,
                                                        int surface_height);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_SDL_SURFACE_OHOS_H_