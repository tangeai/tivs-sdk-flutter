#ifndef _RAPID_SDL_SILENCE_H_
#define _RAPID_SDL_SILENCE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;
typedef struct RAPID_SDL_Aout RAPID_SDL_Aout;
typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;

RAPID_SDL_Vout* RAPID_SDL_Vout_Silence_Create();
RAPID_SDL_Aout* RAPID_SDL_Aout_Silence_Create();

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_SILENCE_H_