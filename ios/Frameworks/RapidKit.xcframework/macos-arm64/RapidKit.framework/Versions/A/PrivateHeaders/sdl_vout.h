#ifndef _RAPID_SDL_VOUT_H_
#define _RAPID_SDL_VOUT_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int RAPID_Boolean;
#define RAPID_FALSE 0
#define RAPID_TRUE 1

typedef struct RAPID_MediaFrame RAPID_MediaFrame;
typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;
typedef struct RAPID_SDL_Vout_Opaque RAPID_SDL_Vout_Opaque;
typedef struct RAPID_SDL_Vout RAPID_SDL_Vout;

typedef struct RAPID_SDL_Class {
  const char* name;
} RAPID_SDL_Class;

// Represents a video frame that can be displayed by SDL.
struct RAPID_SDL_VoutOverlay {
  int w;
  int h;
  int format;
  int pixels_size;
  uint8_t* pixels;
};

RAPID_SDL_VoutOverlay* RAPID_SDL_VoutOverlay_Create(struct RAPID_MediaFrame* frame);

RAPID_Boolean RAPID_SDL_VoutOverlay_FillFrame(struct RAPID_SDL_VoutOverlay* overlay,
                                     struct RAPID_MediaFrame* frame);

RAPID_Boolean RAPID_SDL_VoutOverlay_PixelReset(struct RAPID_SDL_VoutOverlay* overlay);

void RAPID_SDL_VoutOverlay_Free(struct RAPID_SDL_VoutOverlay* overlay);

/// ============================================================================

struct RAPID_SDL_Vout {
  int overlay_format;
  RAPID_SDL_Class* opaque_class;
  RAPID_SDL_Vout_Opaque* opaque;
  void (*free_l)(struct RAPID_SDL_Vout* vout);
  int (*display_overlay)(struct RAPID_SDL_Vout* vout, struct RAPID_SDL_VoutOverlay* overlay);
  int (*display_platform_video)(struct RAPID_SDL_Vout* vout, struct RAPID_MediaFrame* frame);
  struct RAPID_MediaFrame* (*snapshot)(struct RAPID_SDL_Vout* vout);
  int (*get_video_output_size)(struct RAPID_SDL_Vout* vout, int* width, int* height);
  void* (*get_video_decode_target_provider)(struct RAPID_SDL_Vout* vout);
  int (*start_record)(struct RAPID_SDL_Vout* vout, const char* path, int width, int height,
                      int fps, int sample_rate, int channels);
  int (*stop_record)(struct RAPID_SDL_Vout* vout);
  int (*is_recording)(struct RAPID_SDL_Vout* vout);
  int64_t (*record_queue_size)(struct RAPID_SDL_Vout* vout);
  int64_t (*record_duration_ms)(struct RAPID_SDL_Vout* vout);
  int (*record_audio_frame)(struct RAPID_SDL_Vout* vout, struct RAPID_MediaFrame* frame);
 };

void RAPID_SDL_Vout_Free(struct RAPID_SDL_Vout* vout);

int RAPID_SDL_Vout_DisplayOverlay(RAPID_SDL_Vout* vout,
                                  struct RAPID_SDL_VoutOverlay* overlay);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_VOUT_H_
