#ifndef RAPID_MEDIA_PLAYER_VIDEO_DECODE_TARGET_PROVIDER_H_
#define RAPID_MEDIA_PLAYER_VIDEO_DECODE_TARGET_PROVIDER_H_

#include <atomic>

namespace rapid::media {

enum class VideoDecodeTargetType : int {
  kNone = 0,
  kAndroid = 1,
};

struct VideoDecodeTargetSnapshot {
  VideoDecodeTargetType type = VideoDecodeTargetType::kNone;
  void* decode_target = nullptr;
  void* display_target = nullptr;
  int width = 0;
  int height = 0;
  bool valid = false;
  const char* invalid_reason = nullptr;
};

class VideoDecodeTargetProvider {
 public:
  void retain() { _ref_count.fetch_add(1, std::memory_order_relaxed); }
  void release() {
    if (_ref_count.fetch_sub(1, std::memory_order_acq_rel) == 1) {
      delete this;
    }
  }

  virtual VideoDecodeTargetSnapshot snapshot() = 0;
  virtual void invalidate() = 0;

 protected:
  virtual ~VideoDecodeTargetProvider() = default;

 private:
  std::atomic<int> _ref_count{1};
};

}  // namespace rapid::media

#endif  // RAPID_MEDIA_PLAYER_VIDEO_DECODE_TARGET_PROVIDER_H_
