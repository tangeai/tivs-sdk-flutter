#ifndef _RAPID_CORE_PIPE_BRIDGE_H_
#define _RAPID_CORE_PIPE_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  RAPID_CORE_PIPE_STATE_UNDEFINED = 0,
  RAPID_CORE_PIPE_STATE_ATTEMPTING = 1,
  RAPID_CORE_PIPE_STATE_ESTABLISHED = 2,
  RAPID_CORE_PIPE_STATE_ABOLISHED = 3,
  RAPID_CORE_PIPE_STATE_FAILED = 4,
  RAPID_CORE_PIPE_STATE_SHUTDOWN_BY_REMOTE = 5,
  RAPID_CORE_PIPE_STATE_TOKEN_NOT_AVAILABLE = 6,
} RAPID_Core_PipeState;

typedef void (*RAPID_Core_PipeStateFunc)(int status, void* user_context);
typedef void* RAPID_Core_PipeProxy;

RAPID_Core_PipeProxy RAPID_Core_PipeProxy_Create(const char* devide_id);
RAPID_Core_PipeProxy RAPID_Core_PipeProxy_CreateIndependent(const char* device_id);

void RAPID_Core_PipeProxy_Destroy(RAPID_Core_PipeProxy proxy);
// Exclusive query owner; call after releasing instructions, off callback/UI threads.
int RAPID_Core_PipeProxy_DestroyRecordQuery(RAPID_Core_PipeProxy proxy);

void RAPID_Core_PipeProxy_Establish(RAPID_Core_PipeProxy proxy);
void RAPID_Core_PipeProxy_Abolish(RAPID_Core_PipeProxy proxy);

int RAPID_Core_PipeProxy_Status(RAPID_Core_PipeProxy proxy);

void RAPID_Core_PipeProxy_EnableLanMode(RAPID_Core_PipeProxy proxy, int lan_mode);
void RAPID_Core_PipeProxy_SetTransportMode(RAPID_Core_PipeProxy proxy, int mode);

// Borrow both handles for this call; neither is retained or released.
// Destination must be inactive and independent. Returns 1 on success, else 0.
// Keep handles alive; do not establish or destroy the destination concurrently.
int RAPID_Core_PipeProxy_CopyConnectionConfig(RAPID_Core_PipeProxy destination,
                                             RAPID_Core_PipeProxy source);

void RAPID_Core_PipeProxy_SetStatusFunc(RAPID_Core_PipeProxy proxy,
                                        RAPID_Core_PipeStateFunc func,
                                        void* user_context);

void RAPID_Core_PipeProxy_SetStatusSendPort(RAPID_Core_PipeProxy proxy, long long port);

typedef void (*RAPID_Core_InstructResponseFunc)(int state,
                                                const char* buffer,
                                                int buffer_size,
                                                void* user_context);

void RAPID_Core_PipeProxy_InstructRequest(RAPID_Core_PipeProxy proxy,
                                          unsigned int id,
                                          char* buffer,
                                          unsigned int buffer_size,
                                          RAPID_Core_InstructResponseFunc func,
                                          unsigned int timeout_s,
                                          void* user_context);

void RAPID_Core_PipeProxy_InstructRequest_ResponseBySendPort(RAPID_Core_PipeProxy proxy,
                                                             unsigned int id,
                                                             char* buffer,
                                                             unsigned int buffer_size,
                                                             long long send_port,
                                                             unsigned int timeout_s);

void RAPID_Core_PipeToken_Prepare(char* device_id);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_PIPE_BRIDGE_H_
