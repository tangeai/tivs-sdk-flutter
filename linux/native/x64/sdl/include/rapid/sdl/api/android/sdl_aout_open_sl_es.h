#ifdef __ANDROID__

#ifndef _RAPID_ANDROID_SDL_AOUT_SL_ES_H_
#define _RAPID_ANDROID_SDL_AOUT_SL_ES_H_

#ifdef __cplusplus
extern "C" {
#endif


typedef struct RAPID_SDL_Aout RAPID_SDL_Aout;

RAPID_SDL_Aout* RAPID_SDL_Aout_CreateSLES(void* env, int audio_output_mode);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_ANDROID_SDL_AOUT_SL_ES_H_

#endif  // __ANDROID__
