#ifndef _RAPID_SDL_AIN_WASAPI_H_
#define _RAPID_SDL_AIN_WASAPI_H_

#ifdef _WIN32

#ifdef __cplusplus
extern "C" {
#endif

#include "rapid/sdl/api/sdl_ain.h"

RAPID_SDL_Ain* RAPID_SDL_Ain_CreateForWASAPI();

#ifdef __cplusplus
}
#endif

#endif  // _WIN32

#endif  // _RAPID_SDL_AIN_WASAPI_H_

