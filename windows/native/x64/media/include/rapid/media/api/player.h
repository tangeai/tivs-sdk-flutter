#ifndef _RAPID_MEDIA_PLAYER_BRIDGE_H_
#define _RAPID_MEDIA_PLAYER_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "rapid/media/api/pixel_format.h"

typedef void* RAPID_MediaPlayer;
typedef void (*RAPID_MediaPlayer_StateHandler)(int);
;
typedef void* RAPID_SDL_Vout_Opaque_Ptr;
typedef void* RAPID_SDL_Aout_Opaque_Ptr;
typedef void* RAPID_SDL_Pout_Opaque_Ptr;

typedef enum {
  RAPID_MEDIA_RENDER_STATE_UNKNOWN = -1,
  RAPID_MEDIA_RENDER_STATE_STARTED = 0,
  RAPID_MEDIA_RENDER_STATE_BUFFERING = 1,
  RAPID_MEDIA_RENDER_STATE_COMPLETED = 2,
  RAPID_MEDIA_RENDER_STATE_PAUSED = 3
} RAPID_MediaRenderState;

typedef enum {
  RAPID_MEDIA_PLAYER_BUFFERING_MODE_OFF = 0,
  RAPID_MEDIA_PLAYER_BUFFERING_MODE_AUTO = 1,
  RAPID_MEDIA_PLAYER_BUFFERING_MODE_FIXED = 2,
} RAPID_MediaPlayer_BufferingMode;

typedef enum {
  RAPID_MEDIA_PLAYER_CLOCK_MODE_AUDIO = 0,
  RAPID_MEDIA_PLAYER_CLOCK_MODE_VIDEO = 1,
} RAPID_MediaPlayer_ClockMode;

typedef enum {
  RAPID_MEDIA_PLAYER_VIDEO_DECODER_PREFERENCE_AUTO = 0,
  RAPID_MEDIA_PLAYER_VIDEO_DECODER_PREFERENCE_SOFTWARE = 1,
  RAPID_MEDIA_PLAYER_VIDEO_DECODER_PREFERENCE_HARDWARE = 2,
} RAPID_MediaPlayer_VideoDecoderPreference;

typedef struct RAPID_Media_PixelFrame {
  int width;
  int height;
  int pixel_format;  // PIX_FMT_*
  int data_size;
  const unsigned char* data;
} RAPID_Media_PixelFrame;

RAPID_MediaPlayer RAPID_MediaPlayer_Create();
void RAPID_MediaPlayer_Prepare(RAPID_MediaPlayer player, void* provider);
void RAPID_MediaPlayer_Mute(RAPID_MediaPlayer player, int mute);
int RAPID_MediaPlayer_IsMute(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_Start(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_Pause(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_Resume(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_Stop(RAPID_MediaPlayer player);
int RAPID_MediaPlayer_State(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_Flush(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_Destroy(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_BindPlayer(RAPID_MediaPlayer player, RAPID_MediaPlayer main_target);
void RAPID_MediaPlayer_SetVout(RAPID_MediaPlayer player, RAPID_SDL_Vout_Opaque_Ptr vout);
typedef int (*RAPID_MediaPlayer_VoutResizeFunc)(void* vout, int width, int height);
typedef void (*RAPID_MediaPlayer_VoutResetFunc)(void* vout);
// Transfers vout ownership. Hooks borrow it under the player's output lock and must not reenter.
void RAPID_MediaPlayer_SetVoutWithHooks(RAPID_MediaPlayer player, RAPID_SDL_Vout_Opaque_Ptr vout,
                                      RAPID_MediaPlayer_VoutResizeFunc resize,
                                      RAPID_MediaPlayer_VoutResetFunc reset);
int RAPID_MediaPlayer_NotifyVoutSizeChanged(RAPID_MediaPlayer player, int width, int height);
// Consumes both outputs on every path. Returns 1 if attached, 0 if rejected and freed.
// Serializes with Destroy for C-factory players. Hooks follow SetVoutWithHooks semantics.
int RAPID_MediaPlayer_AttachOutputsWithHooks(RAPID_MediaPlayer player,
                                           RAPID_SDL_Vout_Opaque_Ptr vout,
                                           RAPID_SDL_Aout_Opaque_Ptr aout,
                                           RAPID_MediaPlayer_VoutResizeFunc resize,
                                           RAPID_MediaPlayer_VoutResetFunc reset);
void RAPID_MediaPlayer_SetAout(RAPID_MediaPlayer player, RAPID_SDL_Aout_Opaque_Ptr aout);
// Capture synchronously while owning the live C-factory player, before queuing async work.
// The process-local token identifies this instance, survives address reuse, and is 0 if absent.
long long RAPID_MediaPlayer_GetOutputToken(RAPID_MediaPlayer player);
// Consumes both outputs on every path, including stale/zero-token rejection. Returns 1 on success.
int RAPID_MediaPlayer_AttachOutputsForToken(RAPID_MediaPlayer player, long long token,
                                          RAPID_SDL_Vout_Opaque_Ptr vout,
                                          RAPID_SDL_Aout_Opaque_Ptr aout,
                                          RAPID_MediaPlayer_VoutResizeFunc resize,
                                          RAPID_MediaPlayer_VoutResetFunc reset);
// Borrows the matching live player for this call; returns 0 for a stale or zero token.
int RAPID_MediaPlayer_NotifyVoutSizeChangedForToken(
    RAPID_MediaPlayer player, long long token, int width, int height);
int RAPID_MediaPlayer_Capture(RAPID_MediaPlayer player, const char* path);
int RAPID_MediaPlayer_StartRecord(RAPID_MediaPlayer player, const char* path);
int RAPID_MediaPlayer_StopRecord(RAPID_MediaPlayer player);
long long RAPID_MediaPlayer_GetRecordDurationMs(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_EnableBuffering(RAPID_MediaPlayer player, int enable);
void RAPID_MediaPlayer_SetBufferingMode(RAPID_MediaPlayer player,
                                        int mode,
                                        int fixed_water_mark_ms);
void RAPID_MediaPlayer_SetClockMode(RAPID_MediaPlayer player, int mode);

// Configure before prepare. Applies only to the primary local replay provider.
void RAPID_MediaPlayer_SetLocalReplayAudioContinuity(RAPID_MediaPlayer player, int enabled);
void RAPID_MediaPlayer_SetVideoDecoderPreference(RAPID_MediaPlayer player, int preference);
void RAPID_MediaPlayer_SetOverloadWaterMark(RAPID_MediaPlayer player, int value);
void RAPID_MediaPlayer_SetWaterMark(RAPID_MediaPlayer player, int value);
void RAPID_MediaPlayer_SetAutoMaxWaterMark(RAPID_MediaPlayer player, int value);
long long RAPID_MediaPlayer_GetMuxerQueueSize(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_EnableAout(RAPID_MediaPlayer player, int enable);
void RAPID_MediaPlayer_EnableVout(RAPID_MediaPlayer player, int enable);
void RAPID_MediaPlayer_ConfigureAudioProcessing(RAPID_MediaPlayer player,
                                                int ns_level,
                                                int agc_level);
int RAPID_MediaPlayer_GetPixelWidth(RAPID_MediaPlayer player);
int RAPID_MediaPlayer_GetPixelHeight(RAPID_MediaPlayer player);
long long RAPID_MediaPlayer_GetUts(RAPID_MediaPlayer player);
long long RAPID_MediaPlayer_GetPts(RAPID_MediaPlayer player);
int RAPID_MediaPlayer_StartDump(RAPID_MediaPlayer player);
int RAPID_MediaPlayer_StopDump(RAPID_MediaPlayer player);

RAPID_Media_PixelFrame* RAPID_MediaPlayer_GetPixelFrame(RAPID_MediaPlayer player);
RAPID_Media_PixelFrame* RAPID_Media_PixelFrame_Create();
void RAPID_Media_PixelFrame_Free(RAPID_Media_PixelFrame* frame);

typedef void (*RAPID_MediaPlayer_UtsFunc)(long long uts, void* user_data);
typedef void (*RAPID_MediaPlayer_PtsFunc)(long long pts, void* user_data);
typedef void (*RAPID_MediaPlayer_StateFunc)(int render_state, void* user_data);
typedef void (*RAPID_MediaPlayer_PixelSizeFunc)(int width, int height, void* user_data);
typedef void (*RAPID_MediaPlayer_RecordDurationFunc)(long long duration_ms, void* user_data);

void RAPID_MediaPlayer_SetPtsFunc(RAPID_MediaPlayer player,
                                  RAPID_MediaPlayer_PtsFunc func,
                                  void* user_data);
void RAPID_MediaPlayer_SetPixelSizeFunc(RAPID_MediaPlayer player,
                                        RAPID_MediaPlayer_PixelSizeFunc func,
                                        void* user_data);
void RAPID_MediaPlayer_SetUtsFunc(RAPID_MediaPlayer player,
                                  RAPID_MediaPlayer_UtsFunc func,
                                  void* user_data);
void RAPID_MediaPlayer_SetRenderStateFunc(RAPID_MediaPlayer player,
                                          RAPID_MediaPlayer_StateFunc func,
                                          void* user_data);
void RAPID_MediaPlayer_SetRecordDurationFunc(RAPID_MediaPlayer player,
                                             RAPID_MediaPlayer_RecordDurationFunc func,
                                             void* user_data);

void RAPID_MediaPlayer_SetRenderStatusSendPort(RAPID_MediaPlayer player, long long port);
void RAPID_MediaPlayer_SetRecordDurationSendPort(RAPID_MediaPlayer player, long long port);
void RAPID_MediaPlayer_SetPtsSendPort(RAPID_MediaPlayer player, long long port);
void RAPID_MediaPlayer_SetUtsSendPort(RAPID_MediaPlayer player, long long port);

const char* RAPID_MediaPlayer_GetRuntimeMetricsJson(RAPID_MediaPlayer player);
void RAPID_MediaPlayer_FreeJson(const char* json);

const char* RAPID_MediaPlayer_GetStartupMetricsJson(RAPID_MediaPlayer player);

#ifdef __cplusplus
}

inline const char* RAPID_MediaRenderState_ToName(RAPID_MediaRenderState state) {
  switch (state) {
    case RAPID_MEDIA_RENDER_STATE_UNKNOWN:
      return "UNKNOWN";
    case RAPID_MEDIA_RENDER_STATE_STARTED:
      return "STARTED";
    case RAPID_MEDIA_RENDER_STATE_BUFFERING:
      return "BUFFERING";
    case RAPID_MEDIA_RENDER_STATE_COMPLETED:
      return "COMPLETED";
    case RAPID_MEDIA_RENDER_STATE_PAUSED:
      return "PAUSED";
    default:
      return "INVALID";
  }
}
#endif

#endif  // _RAPID_MEDIA_PLAYER_BRIDGE_H_
