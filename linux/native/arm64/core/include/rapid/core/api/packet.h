#ifndef _RAPID_CORE_STREAM_PACKET_H_
#define _RAPID_CORE_STREAM_PACKET_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {

  /* ==========================================
   *       codec id
   * ========================================== */
  RAPID_CORE_CODEC_UNKNOWN = 0x00,
  RAPID_CORE_CODEC_AVC = 0x4E,
  RAPID_CORE_CODEC_HEVC = 0x50,
  RAPID_CORE_CODEC_MJPEG = 0x4F,
  RAPID_CORE_CODEC_G711A = 0x8A,

  /* ==========================================
   *       special codec id
   * ========================================== */
  RAPID_CORE_CODEC_END = 0x100,    /* means no more frame (should be removed) */
  RAPID_CORE_CODEC_SPEED = 0x102,  /* means speed control (should be removed) */
  RAPID_CORE_CODEC_SPECIAL = 0x200 /* means special frame */
} RAPID_Core_StreamCodecID;

typedef enum {
  RAPID_CORE_STREAM_AUDIO_SAMPLE_RATE_8K = 2,
  RAPID_CORE_STREAM_AUDIO_SAMPLE_RATE_16K = 10,
} RAPID_Core_StreamAudioSampleRate;

typedef enum {
  RAPID_CORE_STREAM_TYPE_LIVE = 0,   // live stream
  RAPID_CORE_STREAM_TYPE_LOCAL = 1,  // local stream
  RAPID_CORE_STREAM_TYPE_CLOUD = 2,  // cloud stream
} RAPID_Core_StreamType;

typedef enum {
  RAPID_CORE_VIDEO_FRAME_FLAG_KEY = 0x01,
  RAPID_CORE_VIDEO_FRAME_FLAG_TIMELAPSE = 0x02,
} RAPID_Core_VideoFrameFlag;

typedef struct RAPID_Core_StreamPacket {
  char* buffer;
  int32_t codec_id;
  int32_t sub_type;
  // Video flags may be combined: bit 0 means key frame and bit 1 means timelapse frame.
  // Audio packets use this field as RAPID_Core_StreamAudioSampleRate.
  int32_t frame_type;
  int32_t buffer_size;
  int32_t seq_no;
  int64_t ts;
  int64_t utc_ts;
  int8_t final_packet;
  int8_t speed_packet;
  int8_t speed;               // when codec_id is CODEC_SPEED, speed is valid
  int8_t stream_type;         // stream type, value see RAPID_Core_StreamType
  int8_t resolution_changed;  // video quality, value see RAPID_Core_VideoQuality

  // Special control packets.
  // If audio_exists_packet is 1, audio_exists and audio_effective_utc_ts are valid.
  // audio_effective_utc_ts is the UTC(ms) boundary after which audio_exists applies.
  // Compatibility: unknown control packet fields should be ignored by consumers.
  int8_t audio_exists_packet;
  int8_t audio_exists;
  int64_t audio_effective_utc_ts;

  // Local replay timeline control. timeline_generation is zero for legacy packets.
  // A timeline_reset_packet tells consumers to discard data from older generations.
  uint64_t timeline_generation;
  int8_t timeline_reset_packet;

  // Normalized local replay UTC used only for internal timeline decisions.
  int64_t timeline_utc_ts;
} RAPID_Core_StreamPacket;

typedef struct {
  int32_t timestamp;
  int32_t content_length;
  int32_t codec;
  int32_t sub_type;
  int32_t frame_type;
  int seq_no;
} RAPID_Core_StreamPacket_Header;

RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_Create_From_Buffer(const char* buffer,
                                                                    int32_t buffer_size);

RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_Create();

RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_CreateAudioExistsControl(int8_t stream_type,
                                                                          int32_t sub_type,
                                                                          int64_t effective_utc_ms,
                                                                          int audio_exists);

RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_CreateTimelineReset(int8_t stream_type,
                                                                     int32_t sub_type,
                                                                     uint64_t generation);

RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_Copy(RAPID_Core_StreamPacket* packet);

void RAPID_Core_StreamPacket_Free(RAPID_Core_StreamPacket* packet);

void RAPID_Core_StreamPacket_Fill(RAPID_Core_StreamPacket* packet,
                                  const char* buffer,
                                  int32_t buffer_size);


#ifdef __cplusplus
}

inline const char* RAPID_Core_CodecID_ToName(int32_t codec_id) {
  switch (codec_id) {
    case RAPID_CORE_CODEC_AVC:    return "H264";
    case RAPID_CORE_CODEC_HEVC:   return "H265";
    case RAPID_CORE_CODEC_MJPEG:  return "MJPEG";
    case RAPID_CORE_CODEC_G711A:  return "G711A";
    case RAPID_CORE_CODEC_UNKNOWN: return "";
    default: return "UNKNOWN";
  }
}

#endif

#endif  //_RAPID_CORE_STREAM_PACKET_H_
