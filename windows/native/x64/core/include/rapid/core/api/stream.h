#ifndef _RAPID_CORE_STREAM_BRIDGE_H_
#define _RAPID_CORE_STREAM_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif
typedef struct RAPID_Core_StreamPacket RAPID_Core_StreamPacket;

typedef void* RAPID_Core_StreamProvider;

typedef void* RAPID_Core_LiveStream;
RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateDefault(void* pipe_proxy);
RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateDefaultWithAudio(void* pipe_proxy,
                                                                   int audio_enable);
RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateSecondary(void* pipe_proxy);
RAPID_Core_LiveStream RAPID_Core_LiveStream_CreateSecondaryWithAudio(void* pipe_proxy);
void RAPID_Core_LiveStream_Start(RAPID_Core_LiveStream live_stream);
void RAPID_Core_LiveStream_Stop(RAPID_Core_LiveStream live_stream);
int RAPID_Core_LiveStream_IsStarted(RAPID_Core_LiveStream live_stream);
void RAPID_Core_LiveStream_SwitchQuality(RAPID_Core_LiveStream live_stream, int quality);
void RAPID_Core_LiveStream_SwitchHighQuality(RAPID_Core_LiveStream live_stream);
void RAPID_Core_LiveStream_SwitchLowQuality(RAPID_Core_LiveStream live_stream);
int RAPID_Core_LiveStream_CurrentQuality(RAPID_Core_LiveStream live_stream);
void RAPID_Core_LiveStream_RequestKeyFrame(RAPID_Core_LiveStream live_stream);
void RAPID_Core_LiveStream_Release(RAPID_Core_LiveStream live_stream);
RAPID_Core_StreamProvider RAPID_Core_LiveStream_IndexedProvider(RAPID_Core_LiveStream live_stream,
                                                                unsigned int index);
const char* RAPID_Core_LiveStream_GetMetrics(RAPID_Core_LiveStream live_stream,
                                             unsigned int camera_index);
// Borrow live_stream for this call; the caller must exclude concurrent release.
// Returns an owned JSON copy, freed with FreeMetrics; null on invalid input or allocation failure.
const char* RAPID_Core_LiveStream_GetReceiveMetrics(RAPID_Core_LiveStream live_stream,
                                                   unsigned int camera_index);
void RAPID_Core_LiveStream_FreeMetrics(const char* json);

char* RAPID_Core_LiveStream_GetFirstPacketMetricsJson(RAPID_Core_LiveStream live_stream,
                                                      unsigned int camera_index);

typedef void* RAPID_Core_LocalReplayStream;
typedef enum RAPID_Core_LocalReplaySeekError {
  RAPID_Core_LocalReplaySeekError_UtcMismatch = 1,
  RAPID_Core_LocalReplaySeekError_RecoveryFailed = 2,
} RAPID_Core_LocalReplaySeekError;
typedef enum RAPID_Core_LocalReplayStartMode {
  RAPID_Core_LocalReplayStartMode_Continuous = 0,
  RAPID_Core_LocalReplayStartMode_SingleRecord = 1,
} RAPID_Core_LocalReplayStartMode;
// Seek-only sentinel: use the system time zone; zero explicitly selects UTC.
enum { RAPID_Core_LocalReplayTimezone_Unspecified = -1 };
RAPID_Core_LocalReplayStream RAPID_Core_LocalReplayStream_Create(void* pipe_proxy);
RAPID_Core_LocalReplayStream RAPID_Core_LocalReplayStream_CreateWithAudio(void* pipe_proxy,
                                                                          int audio_enable);
void RAPID_Core_LocalReplayStream_Start(RAPID_Core_LocalReplayStream local_stream);
void RAPID_Core_LocalReplayStream_CompatibleOnResumeInstruct(
    RAPID_Core_LocalReplayStream local_stream);
void RAPID_Core_LocalReplayStream_Prepare(RAPID_Core_LocalReplayStream local_stream,
                                          unsigned int start_timestamp_s,
                                          unsigned int end_timestamp_s);
void RAPID_Core_LocalReplayStream_PrepareWithTimezone(RAPID_Core_LocalReplayStream local_stream,
                                                      unsigned int start_timestamp_s,
                                                      unsigned int end_timestamp_s,
                                                      int timezone_offset_s);
void RAPID_Core_LocalReplayStream_Stop(RAPID_Core_LocalReplayStream local_stream);
int RAPID_Core_LocalReplayStream_IsStarted(RAPID_Core_LocalReplayStream local_stream);
// Legacy ABI wrapper. New callers use SeekWithModeAndTimezone.
void RAPID_Core_LocalReplayStream_Seek(RAPID_Core_LocalReplayStream local_stream,
                                       long long timestamp);
void RAPID_Core_LocalReplayStream_SeekWithModeAndTimezone(
    RAPID_Core_LocalReplayStream local_stream,
    long long timestamp,
    RAPID_Core_LocalReplayStartMode start_mode,
    int timezone_offset_s);
void RAPID_Core_LocalReplayStream_UpdateLastRenderedUtc(RAPID_Core_LocalReplayStream local_stream,
                                                        long long timestamp_ms);
void RAPID_Core_LocalReplayStream_SetSpeed(RAPID_Core_LocalReplayStream local_stream, int speed);
// Deprecated ABI compatibility no-op. Audio always follows the video UTC boundary.
// Both enabled=0 and enabled=1 retain the default local replay protocol behavior.
void RAPID_Core_LocalReplayStream_SetAudioUtcFallback(RAPID_Core_LocalReplayStream local_stream,
                                                     int enabled);
void RAPID_Core_LocalReplayStream_SetSeekErrorSendPort(
    RAPID_Core_LocalReplayStream local_stream, long long port);
void RAPID_Core_LocalReplayStream_Pause(RAPID_Core_LocalReplayStream local_stream);
int RAPID_Core_LocalReplayStream_IsPaused(RAPID_Core_LocalReplayStream local_stream);
void RAPID_Core_LocalReplayStream_Resume(RAPID_Core_LocalReplayStream local_stream);
void RAPID_Core_LocalReplayStream_Release(RAPID_Core_LocalReplayStream local_stream);
RAPID_Core_StreamProvider RAPID_Core_LocalReplayStream_IndexedProvider(
    RAPID_Core_LocalReplayStream local_stream, unsigned int index);
const char* RAPID_Core_LocalReplayStream_GetMetrics(RAPID_Core_LocalReplayStream local_stream,
                                                    unsigned int camera_index);
void RAPID_Core_LocalReplayStream_FreeMetrics(const char* json);

typedef void* RAPID_Core_CloudReplayStream;
typedef enum RAPID_Core_CloudReplayMode {
  RAPID_CORE_CLOUD_REPLAY_MODE_NORMAL = 0,
  RAPID_CORE_CLOUD_REPLAY_MODE_TIMELAPSE = 1,
} RAPID_Core_CloudReplayMode;
typedef void (*RAPID_Core_CloudReplayStream_FileNotFoundFunc)(int timestamp_s, void* user_data);
typedef void (*RAPID_Core_CloudReplayStream_DownloadCompleteFunc)(void* user_data);
typedef void (*RAPID_Core_CloudReplayStream_RetrieveErrorFunc)(int error_code, void* user_data);

enum RAPID_Core_CloudReplayDownloadStartResultType {
  RAPID_Core_CloudReplayDownloadStartResultType_Success = 0,
  RAPID_Core_CloudReplayDownloadStartResultType_NetworkError = 1,
  RAPID_Core_CloudReplayDownloadStartResultType_NoPermitted = 2,
  RAPID_Core_CloudReplayDownloadStartResultType_InvalidParameter = 3,
  RAPID_Core_CloudReplayDownloadStartResultType_InvalidResponse = 4,
  RAPID_Core_CloudReplayDownloadStartResultType_FileTooLong = 5
};

enum RAPID_Core_CloudReplayDownloadStartErrorCode {
  RAPID_Core_CloudReplayDownloadStartErrorCode_Success = 0,
  RAPID_Core_CloudReplayDownloadStartErrorCode_NetworkError = -1,
  RAPID_Core_CloudReplayDownloadStartErrorCode_NoPermitted = -2,
  RAPID_Core_CloudReplayDownloadStartErrorCode_InvalidParameter = -3,
  RAPID_Core_CloudReplayDownloadStartErrorCode_InvalidResponse = -4,
  RAPID_Core_CloudReplayDownloadStartErrorCode_FileTooLong = 0x504
};

typedef struct RAPID_Core_CloudReplayDownloadStartResult {
  int type;
  int error_code;
  unsigned int requested_duration_seconds;
  unsigned int permitted_duration_seconds;
} RAPID_Core_CloudReplayDownloadStartResult;

RAPID_Core_CloudReplayStream RAPID_Core_CloudReplayStream_Create(const char* device_id);
void RAPID_Core_CloudReplayStream_Prepare(RAPID_Core_CloudReplayStream cloud_replay_stream,
                                          unsigned int start_timestamp_s,
                                          unsigned int end_timestamp_s,
                                          const char* storage_id,
                                          const char* file_name_list_json);
void RAPID_Core_CloudReplayStream_PrepareV2(RAPID_Core_CloudReplayStream cloud_replay_stream,
                                            unsigned int start_timestamp_s,
                                            unsigned int end_timestamp_s,
                                            const char* storage_id,
                                            const char* file_name_list_json,
                                            RAPID_Core_CloudReplayMode replay_mode);
void RAPID_Core_CloudReplayStream_Start(RAPID_Core_CloudReplayStream cloud_replay_stream);
RAPID_Core_CloudReplayDownloadStartResult RAPID_Core_CloudReplayStream_StartDownload(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    long long start_timestamp_s,
    long long end_timestamp_s,
    const char* storage_id,
    const char* file_name_list_json);
void RAPID_Core_CloudReplayStream_Seek(RAPID_Core_CloudReplayStream cloud_replay_stream,
                                       unsigned int timestamp_s);
void RAPID_Core_CloudReplayStream_SetSpeed(RAPID_Core_CloudReplayStream cloud_replay_stream,
                                           int speed);
void RAPID_Core_CloudReplayStream_Pause(RAPID_Core_CloudReplayStream cloud_replay_stream);
void RAPID_Core_CloudReplayStream_Resume(RAPID_Core_CloudReplayStream cloud_replay_stream);
void RAPID_Core_CloudReplayStream_Stop(RAPID_Core_CloudReplayStream cloud_replay_stream);
int RAPID_Core_CloudReplayStream_IsPaused(RAPID_Core_CloudReplayStream cloud_replay_stream);
int RAPID_Core_CloudReplayStream_IsStarted(RAPID_Core_CloudReplayStream cloud_replay_stream);
void RAPID_Core_CloudReplayStream_Release(RAPID_Core_CloudReplayStream cloud_replay_stream);
void RAPID_Core_CloudReplayStream_SetFileNotFoundFunc(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    RAPID_Core_CloudReplayStream_FileNotFoundFunc func,
    void* user_data);
void RAPID_Core_CloudReplayStream_SetDownloadCompleteFunc(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    RAPID_Core_CloudReplayStream_DownloadCompleteFunc func,
    void* user_data);
void RAPID_Core_CloudReplayStream_SetRetrieveErrorSendPort(
    RAPID_Core_CloudReplayStream cloud_replay_stream, long long port);
void RAPID_Core_CloudReplayStream_SetRetrieveErrorFunc(
    RAPID_Core_CloudReplayStream cloud_replay_stream,
    RAPID_Core_CloudReplayStream_RetrieveErrorFunc func,
    void* user_data);
void RAPID_Core_CloudReplayStream_EnableDownloadControl(
    RAPID_Core_CloudReplayStream cloud_replay_stream, int enable);
void RAPID_Core_CloudReplayStream_SetFileNotFoundSendPort(
    RAPID_Core_CloudReplayStream cloud_replay_stream, long long port);
void RAPID_Core_CloudReplayStream_SetDownloadCompleteSendPort(
    RAPID_Core_CloudReplayStream cloud_replay_stream, long long port);
RAPID_Core_StreamProvider RAPID_Core_CloudReplayStream_IndexedProvider(
    RAPID_Core_CloudReplayStream cloud_replay_stream, unsigned int index);

typedef void* RAPID_Core_RelayStream;

RAPID_Core_RelayStream RAPID_Core_RelayStream_Create(const char* device_id);
void RAPID_Core_RelayStream_Enqueue(RAPID_Core_RelayStream relay_stream,
                                    RAPID_Core_StreamPacket* packet);
void RAPID_Core_RelayStream_Release(RAPID_Core_RelayStream relay_stream);
RAPID_Core_StreamProvider RAPID_Core_RelayStream_IndexedProvider(
    RAPID_Core_RelayStream relay_stream, unsigned int index);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_STREAM_BRIDGE_H_
