#ifndef RAPID_SDL_AIN_PULSE_AUDIO_H_
#define RAPID_SDL_AIN_PULSE_AUDIO_H_

#include "rapid/sdl/api/sdl_ain.h"

#ifdef __cplusplus
extern "C" {
#endif

RAPID_SDL_Ain* RAPID_SDL_Ain_CreateForPulseAudio();

#ifdef __cplusplus
}
#endif

#endif  // RAPID_SDL_AIN_PULSE_AUDIO_H_
