#ifndef _RAPID_SDL_AOUT_SIMPLE_CALLBACK_H_
#define _RAPID_SDL_AOUT_SIMPLE_CALLBACK_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_Aout RAPID_SDL_Aout;
typedef struct RAPID_SDL_AudioSpec RAPID_SDL_AudioSpec;

typedef void (*RAPID_SDL_AoutFrameCallback)(const uint8_t* buffer,
                                            int len,
                                            const RAPID_SDL_AudioSpec* spec,
                                            void* user_data);

RAPID_SDL_Aout* RAPID_SDL_Aout_SimpleCallback_Create(RAPID_SDL_AoutFrameCallback callback,
                                                      void* user_data);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_AOUT_SIMPLE_CALLBACK_H_
