#ifndef _RAPID_CORE_BRIDGE_PROFILE_TRANSMITTER_H_
#define _RAPID_CORE_BRIDGE_PROFILE_TRANSMITTER_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void* RAPID_Core_ProfileTransmitter;

typedef void (*RAPID_Core_ProfileTransmitter_StateFunc)(int state, void* user_data);

RAPID_Core_ProfileTransmitter RAPID_Core_ProfileTransmitter_Create();
void RAPID_Core_ProfileTransmitter_Prepare(RAPID_Core_ProfileTransmitter transmitter, const char* ssid, const char* password, const char* bind_token);  
void RAPID_Core_ProfileTransmitter_SetStateFunc(RAPID_Core_ProfileTransmitter transmitter, RAPID_Core_ProfileTransmitter_StateFunc callback, void* user_data);
void RAPID_Core_ProfileTransmitter_SetResponseSendPort(RAPID_Core_ProfileTransmitter transmitter, long long send_port);
int RAPID_Core_ProfileTransmitter_GetCurrentState(RAPID_Core_ProfileTransmitter transmitter);
void RAPID_Core_ProfileTransmitter_Start(RAPID_Core_ProfileTransmitter transmitter);
void RAPID_Core_ProfileTransmitter_Stop(RAPID_Core_ProfileTransmitter transmitter);
void RAPID_Core_ProfileTransmitter_Free(RAPID_Core_ProfileTransmitter transmitter);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_BRIDGE_PROFILE_TRANSMITTER_H_
