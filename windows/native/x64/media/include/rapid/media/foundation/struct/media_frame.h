#ifndef _RAPID_MEDIA_FRAMES_STRUCTS_H_
#define _RAPID_MEDIA_FRAMES_STRUCTS_H_

#include <stdint.h>

#include <functional>

#include "rapid/media/api/pixel_format.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  FRAME_NONE,
  FRAME_PIXEL,
  FRAME_AUDIO,
  FRAME_PLATFORM_VIDEO = 3,
} RAPID_Media_FrameType;

typedef enum {
  SAMPLE_FMT_NONE = -1,
  SAMPLE_FMT_U8,   // unsigned 8 bits
  SAMPLE_FMT_S16,  // signed 16 bits
  SAMPLE_FMT_S32,  // signed 32 bits
} RAPID_Media_SampleFormat;

typedef enum {
  VIDEO_DECODER_BACKEND_UNKNOWN = 0,
  VIDEO_DECODER_BACKEND_FFMPEG_SOFTWARE = 1,
  VIDEO_DECODER_BACKEND_ANDROID_MEDIACODEC = 2,
  VIDEO_DECODER_BACKEND_APPLE_VIDEOTOOLBOX = 3,
} RAPID_Media_VideoDecoderBackend;

typedef enum {
  PLATFORM_VIDEO_NONE = 0,
  PLATFORM_VIDEO_ANDROID_ENCODED_PACKET = 1,
  PLATFORM_VIDEO_APPLE_PIXEL_BUFFER = 2,
} RAPID_Media_PlatformVideoType;

typedef enum {
  PLATFORM_VIDEO_ACTION_PENDING = 0,
  PLATFORM_VIDEO_ACTION_DISPLAYED = 1,
  PLATFORM_VIDEO_ACTION_DROPPED = 2,
} RAPID_Media_PlatformVideoActionState;

typedef int (*RAPID_Media_PlatformVideoAction)(void* payload, void* user_data);

struct RAPID_MediaPlatformVideoFrame {
  RAPID_Media_PlatformVideoType platform_type;
  int width;
  int height;
  int64_t uts;
  int64_t pts;
  void* payload;
  void* user_data;
  RAPID_Media_PlatformVideoAction display;
  RAPID_Media_PlatformVideoAction drop;
  RAPID_Media_PlatformVideoAction release;
  int action_state;
  int release_state;
};

// Struct to represent a pixel frame or an audio frame.
struct RAPID_MediaFrame {
  RAPID_Media_FrameType frame_type;  // Type of the frame.

  int64_t uts;  // utc timestamp.

  int64_t pts;    // Presentation timestamp.
  int data_size;  // Size of the data in bytes.
  uint8_t* data;  // Pointer to the pixel/audio data.

  RAPID_Media_PixelFormat pixel_format;  // Pixel format. refer to tgcm_MediaPixelFormat.
  int width;                             // Width of the frame.
  int height;                            // Height of the frame.
  int line_size;                         // Size of a line in bytes.

  RAPID_Media_SampleFormat
      sample_format;       // Sample format. refer to tgcm_MediaSampleFormat. like 16-bits-PCM
  int channels;            // Number of channels , normally 1 or 2.
  int sample_rate;         // Frequency. (Hz) like 44100 / 8000 / 16000
  int64_t channel_layout;  // Channel layout.
  int nb_samples;          // Number of samples in current frame.

  uint64_t timeline_generation;

  RAPID_MediaPlatformVideoFrame* platform_video;

  // Decoder origin, preserved by copies and pixel conversions; not a storage discriminator.
  // Use frame_type, pixel_format, and platform_type to select data or platform payload.
  RAPID_Media_VideoDecoderBackend decoder_backend;
};

RAPID_MediaFrame* RAPID_MediaFrame_Copy(const struct RAPID_MediaFrame* src);

void RAPID_MediaFrame_Free(struct RAPID_MediaFrame* frame);

int RAPID_MediaPlatformVideoFrame_Display(struct RAPID_MediaFrame* frame);

int RAPID_MediaPlatformVideoFrame_Drop(struct RAPID_MediaFrame* frame);

void RAPID_MediaPlatformVideoFrame_Release(struct RAPID_MediaFrame* frame);

#ifdef __cplusplus
}

namespace rapid::media {
using MediaFrameCallback = std::function<void(RAPID_MediaFrame*)>;
}

#endif

#endif  // _RAPID_MEDIA_FRAMES_STRUCTS_H_
