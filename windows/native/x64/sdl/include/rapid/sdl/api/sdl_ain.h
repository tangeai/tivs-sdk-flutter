#ifndef _RAPID_SDL_AIN_H_
#define _RAPID_SDL_AIN_H_

#include "rapid/core/api/proto_type.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum RAPID_SDL_Ain_SampleRate {
  RAPID_SDL_AIN_SAMPLE_RATE_8K = 0,
  RAPID_SDL_AIN_SAMPLE_RATE_16K = 1,
} RAPID_SDL_Ain_SampleRate;

typedef struct RAPID_SDL_Ain_Opaque RAPID_SDL_Ain_Opaque;
typedef struct RAPID_SDL_Ain RAPID_SDL_Ain;

typedef struct RAPID_SDL_Ain_Class {
  const char* name;
} RAPID_SDL_Ain_Class;

typedef void (*RAPID_SDL_Ain_OnDataFunc)(RAPID_SDL_Ain* ain,
                                         const char* buffer,
                                         int size,
                                         void* user_data);

struct RAPID_SDL_Ain {
  RAPID_SDL_Ain_Class* opaque_class;

  RAPID_SDL_Ain_Opaque* opaque;

  int (*open_audio)(struct RAPID_SDL_Ain* ain,
                    RAPID_SDL_Ain_OnDataFunc on_data_func,
                    void* user_data,
                    RAPID_SDL_Ain_SampleRate sample_rate);

  void (*close_audio)(struct RAPID_SDL_Ain* ain);

  void (*free_l)(struct RAPID_SDL_Ain* ain);
};

RAPID_Boolean RAPID_SDL_AinOpenAudio(RAPID_SDL_Ain* ain,
                                     RAPID_SDL_Ain_OnDataFunc on_data_func,
                                     void* user_data,
                                     RAPID_SDL_Ain_SampleRate sample_rate);

void RAPID_SDL_AinCloseAudio(RAPID_SDL_Ain* ain);

void RAPID_SDL_AinFree(RAPID_SDL_Ain* ain);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_AIN_H_
