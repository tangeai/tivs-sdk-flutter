#include "rapid_kit/rapid_kit_texture.h"

#include <flutter/texture_registrar.h>

#include <chrono>
#include <thread>
#include <vector>

namespace rapid_kit {

// YUV420P to RGBA conversion function (Windows expects RGBA format)
static void ConvertYUV420PToRGBA(const uint8_t* yuv420p_data, int width, int height, uint8_t* rgba_data) {
  const int y_size = width * height;
  const int uv_width = width / 2;
  const int uv_height = height / 2;
  const int uv_size = uv_width * uv_height;

  const uint8_t* y_src = yuv420p_data;
  const uint8_t* u_src = yuv420p_data + y_size;
  const uint8_t* v_src = yuv420p_data + y_size + uv_size;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      const int y_index = y * width + x;
      const int uv_index = (y / 2) * uv_width + (x / 2);

      const int Y = y_src[y_index];
      const int U = u_src[uv_index] - 128;
      const int V = v_src[uv_index] - 128;

      // YUV to RGB conversion (ITU-R BT.601)
      int R = Y + static_cast<int>(1.402 * V);
      int G = Y - static_cast<int>(0.344 * U) - static_cast<int>(0.714 * V);
      int B = Y + static_cast<int>(1.772 * U);

      // Clamp values to [0, 255]
      R = R < 0 ? 0 : (R > 255 ? 255 : R);
      G = G < 0 ? 0 : (G > 255 ? 255 : G);
      B = B < 0 ? 0 : (B > 255 ? 255 : B);

      // RGBA format (Red, Green, Blue, Alpha)
      const int pixel_index = y_index * 4;
      rgba_data[pixel_index + 0] = static_cast<uint8_t>(R);    // Red
      rgba_data[pixel_index + 1] = static_cast<uint8_t>(G);    // Green
      rgba_data[pixel_index + 2] = static_cast<uint8_t>(B);    // Blue
      rgba_data[pixel_index + 3] = 255;                        // Alpha
    }
  }
}

RapidTexture::RapidTexture(flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar), width_(0), height_(0), is_detached_(false) {
  buffer_.buffer = nullptr;
  buffer_.width = 0;
  buffer_.height = 0;

  texture_variant_ = std::make_unique<flutter::TextureVariant>(
      std::in_place_type_t<flutter::PixelBufferTexture>(),
      [this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
          std::lock_guard<std::mutex> lock(mutex_);
          return &buffer_;
      }
  );

  texture_id_ = texture_registrar_->RegisterTexture(texture_variant_.get());
}

RapidTexture::~RapidTexture() {
}

void RapidTexture::MarkDetached() {
  is_detached_ = true;
  if (texture_registrar_ && texture_id_ != -1) {
    texture_registrar_->UnregisterTexture(texture_id_);
  }
}

int64_t RapidTexture::GetTextureId() const { return texture_id_; }

void RapidTexture::UpdateOverlay(const RAPID_SDL_VoutOverlay* overlay) {
  if (!overlay || !overlay->pixels || overlay->w <= 0 || overlay->h <= 0) {
    return;
  }

  if (is_detached_) {
    return;
  }
    
  std::lock_guard<std::mutex> lock(mutex_);

  const bool size_changed = (width_ != overlay->w) || (height_ != overlay->h);

  if (size_changed) {
    width_ = overlay->w;
    height_ = overlay->h;
  }

  const int required_pixels = overlay->w * overlay->h;
  const size_t rgba_bytes = required_pixels * 4;  // RGBA uses 4 bytes per pixel
  
  // Check if input has enough YUV420P data (width * height * 1.5)
  const size_t required_yuv_bytes = required_pixels * 3 / 2;
  if (static_cast<size_t>(overlay->pixels_size) < required_yuv_bytes) {
    return;
  }

  if (size_changed) {
    pixel_buffer_.resize(rgba_bytes);
  }

  // Convert YUV420P to RGBA
  ConvertYUV420PToRGBA(overlay->pixels, overlay->w, overlay->h, pixel_buffer_.data());

  buffer_.buffer = pixel_buffer_.data();
  buffer_.width = overlay->w;
  buffer_.height = overlay->h;

  if (texture_variant_) {
    texture_registrar_->MarkTextureFrameAvailable(texture_id_);
  }
}

}  // namespace rapid_kit