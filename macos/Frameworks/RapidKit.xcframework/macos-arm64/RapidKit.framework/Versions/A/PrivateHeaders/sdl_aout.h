#ifndef _RAPID_SDL_AOUT_H_
#define _RAPID_SDL_AOUT_H_

#if defined(_WIN32)
#include <cstdint>
#else
#include <stdint.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int RAPID_Boolean;
#define RAPID_FALSE 0
#define RAPID_TRUE 1

typedef struct RAPID_SDL_Aout_Opaque RAPID_SDL_Aout_Opaque;
typedef struct RAPID_SDL_Aout RAPID_SDL_Aout;
typedef struct RAPID_MediaFrame RAPID_MediaFrame;

// The writable buffer is borrowed for this call; return the number of bytes filled.
// user_data is borrowed and must remain valid until audio callbacks have stopped.
typedef int (*RAPID_SDL_AudioCallback)(void* user_data, uint8_t* buffer, int len);

typedef struct RAPID_SDL_AudioSpec {
  int sample_rate;  /**< Frequency. (Hz) like 44100 / 8000 / 16000 */
  uint16_t format;  /**< Audio data format */
  uint8_t channels; /**< Number of channels: 1 mono, 2 stereo */
  int samples;      /**< Audio buffer size in samples */
  RAPID_SDL_AudioCallback callback;
  void* user_data;
} RAPID_SDL_AudioSpec;

RAPID_SDL_AudioSpec* RAPID_SDL_AudioSpec_Create(RAPID_MediaFrame* frame);
void RAPID_SDL_AudioSpec_SetCallback(RAPID_SDL_AudioSpec* spec,
                                   RAPID_SDL_AudioCallback callback,
                                   void* user_data);

typedef struct RAPID_SDL_Aout_Class {
  const char* name;
} RAPID_SDL_Aout_Class;

struct RAPID_SDL_Aout {
  RAPID_SDL_Aout_Class* opaque_class;
  RAPID_SDL_Aout_Opaque* opaque;

  int (*open_audio)(struct RAPID_SDL_Aout* aout, const RAPID_SDL_AudioSpec* spec);
  void (*pause_audio)(struct RAPID_SDL_Aout* aout, RAPID_Boolean pause_on);
  void (*flush_audio)(struct RAPID_SDL_Aout* aout);
  void (*set_volume)(struct RAPID_SDL_Aout* aout, int volume);
  void (*close_audio)(struct RAPID_SDL_Aout* aout);
  void (*free_l)(struct RAPID_SDL_Aout* aout);

  // Android only
  int (*func_get_audio_session_id)(RAPID_SDL_Aout* aout);
};

RAPID_Boolean RAPID_SDL_AoutOpenAudio(RAPID_SDL_Aout* aout, const RAPID_SDL_AudioSpec* desired);

void RAPID_SDL_AoutPauseAudio(RAPID_SDL_Aout* aout, RAPID_Boolean pause_on);

void RAPID_SDL_AoutFlushAudio(RAPID_SDL_Aout* aout);

void RAPID_SDL_AoutSetVolume(RAPID_SDL_Aout* aout, int volume);

void RAPID_SDL_AoutCloseAudio(RAPID_SDL_Aout* aout);
void RAPID_SDL_AoutFlushAudio(RAPID_SDL_Aout* aout);
void RAPID_SDL_AoutFree(RAPID_SDL_Aout* aout);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_AOUT_H_
