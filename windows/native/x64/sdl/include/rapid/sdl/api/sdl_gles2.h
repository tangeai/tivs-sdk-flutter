#ifndef _RAPID_SDL_GLES2_H_
#define _RAPID_SDL_GLES2_H_

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2platform.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_SDL_VoutOverlay RAPID_SDL_VoutOverlay;

#ifdef DEBUG
#define RAPID_GLES2_checkError_TRACE(op)
#define RAPID_GLES2_checkError_DEBUG(op)
#else
#define RAPID_GLES2_checkError_TRACE(op) RAPID_GLES2_checkError(op)
#define RAPID_GLES2_checkError_DEBUG(op) RAPID_GLES2_checkError(op)
#endif

void RAPID_GLES2_printString(const char *name, GLenum s);
void RAPID_GLES2_checkError(const char *op);

GLuint RAPID_GLES2_loadShader(GLenum shader_type, const char *shader_source);

#define RAPID_GLES2_MAX_PLANE 3
typedef struct RAPID_GLES2_Renderer RAPID_GLES2_Renderer;

RAPID_GLES2_Renderer *RAPID_GLES2_Renderer_Create(RAPID_SDL_VoutOverlay *overlay);
void RAPID_GLES2_Renderer_Reset(RAPID_GLES2_Renderer *renderer);
void RAPID_GLES2_Renderer_Free(RAPID_GLES2_Renderer *renderer);
void RAPID_GLES2_Renderer_FreeP(RAPID_GLES2_Renderer **renderer);
GLboolean RAPID_GLES2_Renderer_SetupGLES();
GLboolean RAPID_GLES2_Renderer_isValid(RAPID_GLES2_Renderer *renderer);
GLboolean RAPID_GLES2_Renderer_isFormat(RAPID_GLES2_Renderer *renderer, int format);
GLboolean RAPID_GLES2_Renderer_Use(RAPID_GLES2_Renderer *renderer);
GLboolean RAPID_GLES2_Renderer_RenderOverlay(RAPID_GLES2_Renderer *renderer,
                                             RAPID_SDL_VoutOverlay *overlay);

#define RAPID_GLES2_SCALING_STRETCH (0)     // Stretch to fill view bounds.
#define RAPID_GLES2_SCALING_ASPECT_FIT (1)  // Preserve aspect ratio; fit within view bounds.

#define RAPID_GLES2_GRAVITY_RESIZE RAPID_GLES2_SCALING_STRETCH
#define RAPID_GLES2_GRAVITY_RESIZE_ASPECT RAPID_GLES2_SCALING_ASPECT_FIT

GLboolean RAPID_GLES2_Renderer_setSurfaceSize(RAPID_GLES2_Renderer *renderer, GLsizei width, GLsizei height);
GLboolean RAPID_GLES2_Renderer_setScalingMode(RAPID_GLES2_Renderer *renderer, int scaling_mode);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_GLES2_H_
