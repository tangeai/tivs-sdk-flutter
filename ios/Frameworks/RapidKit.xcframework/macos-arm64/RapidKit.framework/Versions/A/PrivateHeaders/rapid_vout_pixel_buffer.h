//
//  rapid_vout_pixel_buffer.h
//  Rapid
//
//  Created by Allen Feng on 2024/6/5.
//

#ifndef rapid_vout_pixel_buffer_h
#define rapid_vout_pixel_buffer_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;
typedef struct RAPID_MediaFrame RAPID_MediaFrame;

// Borrows the buffer owned by frame; retain it before storing beyond the frame lifetime.
void* RAPID_MediaFrame_GetApplePixelBuffer(const RAPID_MediaFrame* frame);
typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;
typedef struct RAPID_SDL_VoutOverlay_CVPixelBuffer RAPID_SDL_VoutOverlay_CVPixelBuffer;

struct RAPID_SDL_VoutOverlay_CVPixelBuffer {
  int w;
  int h;
  void* pixel_buffer;
};

typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;

typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;

typedef struct RAPID_SDL_VoutOverlay_CVPixelBuffer RAPID_SDL_VoutOverlay_CVPixelBuffer;

typedef int (*DisplayCVPixelBufferFunc)(RAPID_SDL_VoutOverlay_CVPixelBuffer* overlay,
                                        void* context);

RAPID_SDL_Vout* RAPID_SDL_Vout_CreateForCVPixelBuffer(DisplayCVPixelBufferFunc func, void* context);

RAPID_SDL_VoutOverlay_CVPixelBuffer* RAPID_SDL_VoutOverlay_CVPixelBuffer_Create(
    RAPID_SDL_VoutOverlay* overlay);

void RAPID_SDL_VoutOverlay_CVPixelBuffer_Free(RAPID_SDL_VoutOverlay_CVPixelBuffer* overlay);

int RAPID_SDL_Vout_PixelBuffer_Binding(uintptr_t media_player_ptr,
                                       DisplayCVPixelBufferFunc func,
                                       void* context);

int RAPID_MediaChat_AttachAin(uintptr_t media_chat_ptr);

int RAPID_IOS_VoiceProcessingIO_Binding(uintptr_t media_player_ptr,
                                        uintptr_t media_chat_ptr);

int RAPID_IOS_DefaultAudioIO_Binding(uintptr_t media_player_ptr,
                                     uintptr_t media_chat_ptr);

#ifdef __cplusplus
}
#endif

#endif /* rapid_vout_pixel_buffer_h */
