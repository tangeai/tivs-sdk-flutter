#include "rapid_kit_texture.h"

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <vector>

#include "rapid/media/api/pixel_format.h"

namespace {

struct TextureState {
  explicit TextureState(FlTextureRegistrar* texture_registrar)
      : registrar(FL_TEXTURE_REGISTRAR(g_object_ref(texture_registrar))) {}

  ~TextureState() { g_object_unref(registrar); }

  FlTextureRegistrar* registrar;
  std::mutex mutex;
  std::vector<uint8_t> frame_buffer;
  std::vector<uint8_t> render_buffer;
  uint32_t width = 0;
  uint32_t height = 0;
  std::atomic<bool> detached{false};
};

uint8_t clamp_color(int value) { return static_cast<uint8_t>(std::max(0, std::min(value, 255))); }

bool convert_yuv420p(const RAPID_SDL_VoutOverlay* overlay, std::vector<uint8_t>* output) {
  const int width = overlay->w;
  const int height = overlay->h;
  const size_t y_size = static_cast<size_t>(width) * height;
  const size_t uv_size = static_cast<size_t>(width / 2) * (height / 2);
  if ((width & 1) != 0 || (height & 1) != 0 ||
      static_cast<size_t>(overlay->pixels_size) < y_size + uv_size * 2) {
    return false;
  }

  const uint8_t* y_plane = overlay->pixels;
  const uint8_t* u_plane = y_plane + y_size;
  const uint8_t* v_plane = u_plane + uv_size;
  output->resize(y_size * 4);

  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      const size_t y_index = static_cast<size_t>(y) * width + x;
      const size_t uv_index = static_cast<size_t>(y / 2) * (width / 2) + (x / 2);
      const int luminance = y_plane[y_index];
      const int u = u_plane[uv_index] - 128;
      const int v = v_plane[uv_index] - 128;
      const size_t pixel_index = y_index * 4;
      (*output)[pixel_index] = clamp_color(luminance + static_cast<int>(1.402 * v));
      (*output)[pixel_index + 1] =
          clamp_color(luminance - static_cast<int>(0.344 * u) - static_cast<int>(0.714 * v));
      (*output)[pixel_index + 2] = clamp_color(luminance + static_cast<int>(1.772 * u));
      (*output)[pixel_index + 3] = 255;
    }
  }
  return true;
}

bool copy_rgba(const RAPID_SDL_VoutOverlay* overlay, std::vector<uint8_t>* output) {
  const size_t bytes = static_cast<size_t>(overlay->w) * overlay->h * 4;
  if (static_cast<size_t>(overlay->pixels_size) < bytes) return false;
  output->assign(overlay->pixels, overlay->pixels + bytes);
  return true;
}

bool convert_bgra(const RAPID_SDL_VoutOverlay* overlay, std::vector<uint8_t>* output) {
  if (!copy_rgba(overlay, output)) return false;
  for (size_t index = 0; index < output->size(); index += 4) {
    std::swap((*output)[index], (*output)[index + 2]);
  }
  return true;
}

}  // namespace

struct _RapidTexture {
  FlPixelBufferTexture parent_instance;
  TextureState* state;
};

G_DEFINE_TYPE(RapidTexture, rapid_texture, fl_pixel_buffer_texture_get_type())

static gboolean rapid_texture_copy_pixels(FlPixelBufferTexture* texture,
                                          const uint8_t** out_buffer,
                                          uint32_t* width,
                                          uint32_t* height,
                                          GError**) {
  auto* self = RAPID_TEXTURE(texture);
  std::lock_guard<std::mutex> lock(self->state->mutex);
  if (self->state->frame_buffer.empty()) return FALSE;
  self->state->render_buffer = self->state->frame_buffer;
  *out_buffer = self->state->render_buffer.data();
  *width = self->state->width;
  *height = self->state->height;
  return TRUE;
}

static void rapid_texture_dispose(GObject* object) {
  auto* self = RAPID_TEXTURE(object);
  delete self->state;
  self->state = nullptr;
  G_OBJECT_CLASS(rapid_texture_parent_class)->dispose(object);
}

static void rapid_texture_class_init(RapidTextureClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = rapid_texture_dispose;
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = rapid_texture_copy_pixels;
}

static void rapid_texture_init(RapidTexture* self) { self->state = nullptr; }

RapidTexture* rapid_texture_new(FlTextureRegistrar* registrar) {
  auto* texture = RAPID_TEXTURE(g_object_new(rapid_texture_get_type(), nullptr));
  texture->state = new TextureState(registrar);
  return texture;
}

void rapid_texture_update_overlay(RapidTexture* texture, const RAPID_SDL_VoutOverlay* overlay) {
  if (!texture || !texture->state || !overlay || !overlay->pixels || overlay->w <= 0 ||
      overlay->h <= 0 || texture->state->detached.load()) {
    return;
  }

  bool converted = false;
  {
    std::lock_guard<std::mutex> lock(texture->state->mutex);
    if (overlay->format == PIX_FMT_YUV420P) {
      converted = convert_yuv420p(overlay, &texture->state->frame_buffer);
    } else if (overlay->format == PIX_FMT_RGBA) {
      converted = copy_rgba(overlay, &texture->state->frame_buffer);
    } else if (overlay->format == PIX_FMT_BGRA) {
      converted = convert_bgra(overlay, &texture->state->frame_buffer);
    }
    if (converted) {
      texture->state->width = static_cast<uint32_t>(overlay->w);
      texture->state->height = static_cast<uint32_t>(overlay->h);
    }
  }

  if (converted && !texture->state->detached.load()) {
    fl_texture_registrar_mark_texture_frame_available(texture->state->registrar,
                                                      FL_TEXTURE(texture));
  }
}

void rapid_texture_detach(RapidTexture* texture) {
  if (!texture || !texture->state || texture->state->detached.exchange(true)) return;
  fl_texture_registrar_unregister_texture(texture->state->registrar, FL_TEXTURE(texture));
}
