#ifndef _RAPID_MEDIA_CAPTURE_BRIDGE_H_
#define _RAPID_MEDIA_CAPTURE_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  RAPID_MEDIA_CAPTURE_STATE_UNKNOWN = 0,
  RAPID_MEDIA_CAPTURE_STATE_STARTED = 1,
  RAPID_MEDIA_CAPTURE_STATE_COMPLETED = 2,
  RAPID_MEDIA_CAPTURE_STATE_ERROR = 3,
  RAPID_MEDIA_CAPTURE_STATE_STOPPED = 4,
} RAPID_MediaCaptureState;

typedef void (*RAPID_MediaCapture_StateFunc)(int state, void* user_data);
typedef void (*RAPID_MediaCapture_UtsFunc)(long long uts_ms, void* user_data);

typedef void* RAPID_MediaCapture;

RAPID_MediaCapture RAPID_MediaCapture_Create();
void RAPID_MediaCapture_Destroy(RAPID_MediaCapture capture);
void RAPID_MediaCapture_Prepare(RAPID_MediaCapture capture, void* provider);
void RAPID_MediaCapture_SetTimeline(RAPID_MediaCapture capture,
                                    long long start_utc_ms,
                                    long long end_utc_ms);
void RAPID_MediaCapture_Start(RAPID_MediaCapture capture, const char* output_file_path);
void RAPID_MediaCapture_Stop(RAPID_MediaCapture capture);
long long RAPID_MediaCapture_GetUts(RAPID_MediaCapture capture);
RAPID_MediaCaptureState RAPID_MediaCapture_CurrentState(RAPID_MediaCapture capture);

void RAPID_MediaCapture_SetStateFunc(RAPID_MediaCapture capture,
                                     RAPID_MediaCapture_StateFunc func,
                                     void* user_data);

void RAPID_MediaCapture_SetUtsFunc(RAPID_MediaCapture capture,
                                   RAPID_MediaCapture_UtsFunc func,
                                   void* user_data);

void RAPID_MediaCapture_SetStateSendPort(RAPID_MediaCapture capture, long long port);
void RAPID_MediaCapture_SetUtsSendPort(RAPID_MediaCapture capture, long long port);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_MEDIA_CAPTURE_BRIDGE_H_
