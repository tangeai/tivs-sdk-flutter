#ifndef _RAPID_MEDIA_CHAT_BRIDGE_H_
#define _RAPID_MEDIA_CHAT_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void* RAPID_MediaChat;

typedef void* RAPID_SDL_Ain_Opaque_Ptr;
typedef void* RAPID_Core_ChatChannel_Opaque_Ptr;

typedef enum {
  RAPID_MEDIA_CHAT_AUDIO_SAMPLE_RATE_8K = 0,
  RAPID_MEDIA_CHAT_AUDIO_SAMPLE_RATE_16K = 1
} RAPID_MediaChatAudioSampleRate;

RAPID_MediaChat RAPID_MediaChat_Create();
void RAPID_MediaChat_SetAudioSampleRate(RAPID_MediaChat chat, RAPID_MediaChatAudioSampleRate sample_rate);
int RAPID_MediaChat_IsStarted(RAPID_MediaChat chat);
void RAPID_MediaChat_Start(RAPID_MediaChat chat);
void RAPID_MediaChat_Stop(RAPID_MediaChat chat);
void RAPID_MediaChat_Release(RAPID_MediaChat chat);
int RAPID_MediaChat_StartDump(RAPID_MediaChat chat);
int RAPID_MediaChat_StopDump(RAPID_MediaChat chat);
void RAPID_MediaChat_SetAin(RAPID_MediaChat chat, RAPID_SDL_Ain_Opaque_Ptr ain);
void RAPID_MediaChat_SetChatChannel(RAPID_MediaChat chat, RAPID_Core_ChatChannel_Opaque_Ptr channel);

void RAPID_MediaChat_ConfigureAudioProcessing(RAPID_MediaChat chat,
                                              int ns_level,
                                              int aec_level,
                                              int agc_level);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_MEDIA_CHAT_BRIDGE_H_
