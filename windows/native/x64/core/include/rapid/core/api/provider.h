#ifndef _RAPID_CORE_API_PROVIDER_H_
#define _RAPID_CORE_API_PROVIDER_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_Core_StreamPacket RAPID_Core_StreamPacket;
typedef void* RAPID_Core_StreamProvider;

typedef void (*RAPID_Core_StreamPacketListener)(RAPID_Core_StreamPacket* packet, void* user_data);

void RAPID_Core_StreamProvider_SetPacketFunc(RAPID_Core_StreamProvider provider,
                                             RAPID_Core_StreamPacketListener func,
                                             void* user_data);
void RAPID_Core_StreamProvider_RemovePacketFunc(RAPID_Core_StreamProvider provider);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_API_PROVIDER_H_
