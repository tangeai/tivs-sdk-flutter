#ifndef _RAPID_SDL_VOUT_SIMPLE_CALLBACK_H_
#define _RAPID_SDL_VOUT_SIMPLE_CALLBACK_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;
typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;

typedef void (*RAPID_SDL_VoutFrameCallback)(const RAPID_SDL_VoutOverlay* overlay, void* user_data);

RAPID_SDL_Vout* RAPID_SDL_Vout_SimpleCallback_Create(RAPID_SDL_VoutFrameCallback frame_cb, void* user_data);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_VOUT_SIMPLE_CALLBACK_H_