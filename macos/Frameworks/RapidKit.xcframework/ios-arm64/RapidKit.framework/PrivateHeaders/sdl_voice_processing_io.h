#ifndef RAPID_SDL_VOICE_PROCESSING_IO_H
#define RAPID_SDL_VOICE_PROCESSING_IO_H

#include <RapidKit/sdl_ain.h>
#include <RapidKit/sdl_aout.h>

#ifdef __cplusplus
extern "C" {
#endif

RAPID_Boolean RAPID_SDL_VoiceProcessingIO_CreatePair(RAPID_SDL_Ain** ain,
                                                      RAPID_SDL_Aout** aout);

#ifdef __cplusplus
}
#endif

#endif  // RAPID_SDL_VOICE_PROCESSING_IO_H
