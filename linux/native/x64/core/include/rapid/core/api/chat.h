#ifndef _RAPID_CORE_CHANNEL_CHAT_BRIDGE_H_
#define _RAPID_CORE_CHANNEL_CHAT_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void* RAPID_Core_ChatChannel;

typedef enum {
  RAPID_CORE_CHAT_AUDIO_SAMPLE_RATE_8K = 0,
  RAPID_CORE_CHAT_AUDIO_SAMPLE_RATE_16K = 1
} RAPID_Core_ChatAudioSampleRate;

RAPID_Core_ChatChannel RAPID_Core_ChatChannel_Create(void* pipe_proxy);
void RAPID_Core_ChatChannel_SetAudioSampleRate(RAPID_Core_ChatChannel channel, RAPID_Core_ChatAudioSampleRate sample_rate);
void RAPID_Core_ChatChannel_Free(RAPID_Core_ChatChannel channel);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_CORE_CHANNEL_CHAT_BRIDGE_H_
