#ifdef __ANDROID__

#ifndef _RAPID_ANDROID_SDL_ANATIVEWINDOW_H_
#define _RAPID_ANDROID_SDL_ANATIVEWINDOW_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;

RAPID_SDL_Vout* RAPID_SDL_Vout_CreateForANativeWindow(void* env, void* surface);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_ANDROID_SDL_ANATIVEWINDOW_H_

#endif  // __ANDROID__