#ifndef _RAPID_CORE_PERSISTENT_CHANNEL_ADAPTER_H_
#define _RAPID_CORE_PERSISTENT_CHANNEL_ADAPTER_H_

#ifdef __cplusplus
extern "C" {
#endif

enum RAPID_Core_PersistentChannelState {
  RAPID_CORE_PERSISTENT_CHANNEL_STATE_DISCONNECTED = 0,
  RAPID_CORE_PERSISTENT_CHANNEL_STATE_CONNECTING = 1,
  RAPID_CORE_PERSISTENT_CHANNEL_STATE_CONNECTED = 2,
};

typedef void (*RAPID_Core_PersistentChannelStateFunc)(int state,
                                                      const char* reason,
                                                      void* user_context);

typedef void (*RAPID_Core_PersistentChannelMessageFunc)(const char* name,
                                                        const char* detail,
                                                        void* user_context);

void RAPID_Core_PersistentChannel_SetStateCallback(RAPID_Core_PersistentChannelStateFunc callback,
                                                   void* user_context);

void RAPID_Core_PersistentChannel_SetStateSendPort(long long port);

void RAPID_Core_PersistentChannel_SetMessageCallback(
    RAPID_Core_PersistentChannelMessageFunc callback, void* user_context);

void RAPID_Core_PersistentChannel_SetMessageSendPort(long long port);

void RAPID_Core_PersistentChannel_Connect();

void RAPID_Core_PersistentChannel_Disconnect();

int RAPID_Core_PersistentChannel_CurrentState();

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_PERSISTENT_CHANNEL_ADAPTER_H_
