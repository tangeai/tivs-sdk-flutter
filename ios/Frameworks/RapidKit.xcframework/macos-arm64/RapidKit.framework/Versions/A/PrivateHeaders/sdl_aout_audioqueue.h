#ifndef _RAPID_SDL_AOUT_APPLE_AUDIO_QUEUE_H_
#define _RAPID_SDL_AOUT_APPLE_AUDIO_QUEUE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_Aout RAPID_SDL_Aout;

RAPID_SDL_Aout* RAPID_SDL_AoutDarwin_CreateForAudioQueue();

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_AOUT_APPLE_AUDIO_QUEUE_H_