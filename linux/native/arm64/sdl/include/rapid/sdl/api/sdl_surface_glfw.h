#ifndef _RAPID_MEDIA_SDL_SURFACE_GLFW_H_
#define _RAPID_MEDIA_SDL_SURFACE_GLFW_H_

#include "rapid/core/api/proto_type.h"
#include "rapid/sdl/api/sdl_misc.h"
#include "rapid/sdl/api/sdl_surface.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GLFWwindow GLFWwindow;

tgc_SDL_Surface* RAPID_SDL_Surface_GLFW_Create(int window_width, int window_height,
                                               const char* title);

GLFWwindow* RAPID_SDL_Surface_GLFW_GetWindow(RAPID_SDL_Surface* surface);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_MEDIA_SDL_SURFACE_GLFW_H_
