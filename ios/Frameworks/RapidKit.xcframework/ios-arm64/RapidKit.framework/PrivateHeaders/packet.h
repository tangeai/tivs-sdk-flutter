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
  RAPID_CORE_VIDEO_FRAME_FLAG_KEY = 0x01,
  RAPID_CORE_VIDEO_FRAME_FLAG_TIMELAPSE = 0x02,
} RAPID_Core_VideoFrameFlag;

struct RAPID_Core_StreamPacket {
  char* buffer;
  int32_t codec_id;
  int32_t sub_type;
  // Video flags may be combined: bit 0 means key frame and bit 1 means timelapse frame.
  // Audio packets use this field as the sample rate value.
  int32_t frame_type;
  int32_t buffer_size;
  int32_t seq_no;
  int64_t ts;
  int64_t utc_ts;
  int8_t final_packet;
  int8_t speed_packet;
  int8_t speed;  // when codec_id is CODEC_SPEED, speed is valid
};

struct RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_Create_From_Buffer(const char* buffer,
                                                                           int32_t buffer_size);

struct RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_Create();

struct RAPID_Core_StreamPacket* RAPID_Core_StreamPacket_Copy(
    struct RAPID_Core_StreamPacket* packet);

void RAPID_Core_StreamPacket_Free(struct RAPID_Core_StreamPacket* packet);

void RAPID_Core_StreamPacket_Fill(struct RAPID_Core_StreamPacket* packet,
                                  const char* buffer,
                                  int32_t buffer_size);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_STREAM_PACKET_H_
