#ifndef RAPID_SDL_AOUT_PULSE_AUDIO_H_
#define RAPID_SDL_AOUT_PULSE_AUDIO_H_

#include "rapid/sdl/api/sdl_aout.h"

#ifdef __cplusplus
extern "C" {
#endif

RAPID_SDL_Aout* RAPID_SDL_Aout_CreateForPulseAudio();

#ifdef __cplusplus
}
#endif

#endif  // RAPID_SDL_AOUT_PULSE_AUDIO_H_
