#ifndef RAPID_SDL_VOICE_PROCESSING_IO_H
#define RAPID_SDL_VOICE_PROCESSING_IO_H

#include "rapid/sdl/api/sdl_ain.h"
#include "rapid/sdl/api/sdl_aout.h"

#ifdef __cplusplus
extern "C" {
#endif

RAPID_Boolean RAPID_SDL_VoiceProcessingIO_CreatePair(RAPID_SDL_Ain** ain,
                                                      RAPID_SDL_Aout** aout);

#ifdef __cplusplus
}
#endif

#endif  // RAPID_SDL_VOICE_PROCESSING_IO_H
