#ifndef _RAPID_AUDIO_DSP_BRIDGE_H_
#define _RAPID_AUDIO_DSP_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef void* RAPID_AudioDsp;
typedef void* RAPID_AudioSpeechDetector;

typedef enum {
  RAPID_AUDIO_LOG_LEVEL_ERROR = 0,
  RAPID_AUDIO_LOG_LEVEL_INFO = 1,
} RAPID_Audio_LogLevel;

typedef void (*RAPID_Audio_LogFunc)(RAPID_Audio_LogLevel level,
                                    const char* tag,
                                    const char* message,
                                    void* user_data);

typedef enum {
  RAPID_AUDIO_RESULT_OK = 0,
  RAPID_AUDIO_RESULT_INVALID_ARGUMENT = -1,
  RAPID_AUDIO_RESULT_UNSUPPORTED = -2,
  RAPID_AUDIO_RESULT_INTERNAL_ERROR = -3,
  RAPID_AUDIO_RESULT_BUFFER_TOO_SMALL = -4,
  RAPID_AUDIO_RESULT_NOT_INITIALIZED = -5,
} RAPID_Audio_Result;

typedef enum {
  RAPID_AUDIO_SAMPLE_RATE_8K = 8000,
  RAPID_AUDIO_SAMPLE_RATE_16K = 16000,
} RAPID_Audio_SampleRate;

typedef enum {
  RAPID_AUDIO_CHANNELS_MONO = 1,
} RAPID_Audio_Channels;

typedef enum {
  RAPID_AUDIO_NS_OFF = 0,
  RAPID_AUDIO_NS_LOW = 1,
  RAPID_AUDIO_NS_HIGH = 2,
} RAPID_Audio_NsLevel;

typedef enum {
  RAPID_AUDIO_AEC_OFF = 0,
  RAPID_AUDIO_AEC_ON = 1,
} RAPID_Audio_AecMode;

typedef enum {
  RAPID_AUDIO_AGC_OFF = 0,
  RAPID_AUDIO_AGC_LOW = 1,
  RAPID_AUDIO_AGC_HIGH = 2,
} RAPID_Audio_AgcProfile;

typedef enum {
  RAPID_AUDIO_PROFILE_RENDER = 0,
  RAPID_AUDIO_PROFILE_CAPTURE = 1,
} RAPID_Audio_ProfileId;

typedef struct {
  RAPID_Audio_SampleRate sample_rate_hz;
  RAPID_Audio_Channels channels;
} RAPID_Audio_DspParams;

typedef struct {
  int profile_id;
  RAPID_Audio_NsLevel ns_level;
  RAPID_Audio_AecMode aec_mode;
  RAPID_Audio_AgcProfile agc_profile;
} RAPID_Audio_DspConfig;

typedef struct {
  int render_in_fifo_frames;
  int capture_in_fifo_frames;
  int last_error;
  int aec_reference_available;
} RAPID_Audio_DspStats;

RAPID_Audio_Result RAPID_Audio_CreateDsp(const RAPID_Audio_DspParams* params,
                                         RAPID_AudioDsp* out_dsp);

void RAPID_Audio_SetLogCallback(RAPID_Audio_LogFunc func, void* user_data);

RAPID_Audio_Result RAPID_Audio_DestroyDsp(RAPID_AudioDsp dsp);

RAPID_Audio_Result RAPID_Audio_Reset(RAPID_AudioDsp dsp);

RAPID_Audio_Result RAPID_Audio_SetConfig(RAPID_AudioDsp dsp, const RAPID_Audio_DspConfig* config);

RAPID_Audio_Result RAPID_Audio_Process(RAPID_AudioDsp dsp,
                                       const int16_t* in,
                                       int in_frames,
                                       int16_t* out,
                                       int out_capacity_frames,
                                       int* out_frames);

RAPID_Audio_Result RAPID_Audio_PushFarend(RAPID_AudioDsp dsp, const int16_t* pcm, int frames);

RAPID_Audio_Result RAPID_Audio_GetStats(RAPID_AudioDsp dsp, RAPID_Audio_DspStats* out_stats);

RAPID_Audio_Result RAPID_Audio_CreateSpeechDetector(const RAPID_Audio_DspParams* params,
                                                    RAPID_AudioSpeechDetector* out_detector);

RAPID_Audio_Result RAPID_Audio_DestroySpeechDetector(RAPID_AudioSpeechDetector detector);

RAPID_Audio_Result RAPID_Audio_ObserveSpeech(RAPID_AudioSpeechDetector detector,
                                            const int16_t* pcm,
                                            int frames,
                                            int* out_active);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_AUDIO_DSP_BRIDGE_H_
