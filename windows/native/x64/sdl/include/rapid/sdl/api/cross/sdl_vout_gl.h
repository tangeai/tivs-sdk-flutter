#ifndef _RAPID_SDL_VOUT_GLFW_SURFACE_H_
#define _RAPID_SDL_VOUT_GLFW_SURFACE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;
typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;
typedef struct RAPID_SDL_Surface RAPID_SDL_Surface;

RAPID_SDL_Vout* RAPID_SDL_Vout_CreateForGL(RAPID_SDL_Surface* surface, void* mutex);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_VOUT_GLFW_SURFACE_H_