#ifndef _RAPID_SDL_SURFACE_H_
#define _RAPID_SDL_SURFACE_H_

#include "rapid/core/api/proto_type.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;
typedef struct RAPID_SDL_Surface_Opaque RAPID_SDL_Surface_Opaque;
typedef struct RAPID_SDL_Surface_Internal_Opaque RAPID_SDL_Surface_Internal_Opaque;
typedef struct RAPID_SDL_Surface tgc_SDL_Surface;

typedef struct RAPID_SDL_Surface {

  RAPID_SDL_Surface_Opaque *opaque;
  RAPID_SDL_Surface_Internal_Opaque *internal_opaque;

  int width;
  int height;

  RAPID_Boolean (*make_current)(struct RAPID_SDL_Surface *sdl_surface);
  RAPID_Boolean (*get_surface_size_func)(struct RAPID_SDL_Surface *sdl_surface, int *width, int *height);
  RAPID_Boolean (*swap_buffers)(struct RAPID_SDL_Surface *sdl_surface);
  void (*terminate_func)(struct RAPID_SDL_Surface *sdl_surface);

} tgc_SDL_Surface;

struct RAPID_SDL_Surface *RAPID_SDL_Surface_Create();

RAPID_Boolean RAPID_SDL_Surface_Display(struct RAPID_SDL_Surface *sdl_surface,
                                        struct RAPID_SDL_VoutOverlay *overlay);

void RAPID_SDL_Surface_Terminate(struct RAPID_SDL_Surface *sdl_surface);

void RAPID_SDL_Surface_Free(struct RAPID_SDL_Surface *sdl_surface);

RAPID_Boolean RAPID_SDL_Surface_SetScalingMode(struct RAPID_SDL_Surface *sdl_surface,
                                               int scaling_mode);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_SURFACE_H_
