#ifndef _RAPID_SDL_SURFACE_IOS_H_
#define _RAPID_SDL_SURFACE_IOS_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int RAPID_Boolean;
#define RAPID_FALSE 0
#define RAPID_TRUE 1

typedef struct RAPID_SDL_Surface RAPID_SDL_Surface;

// iOS专用的Surface创建函数
struct RAPID_SDL_Surface* RAPID_SDL_Surface_iOS_Create();

// 设置iOS的渲染层
RAPID_Boolean RAPID_SDL_Surface_iOS_SetLayer(struct RAPID_SDL_Surface* sdl_surface, void* layer);

#ifdef __cplusplus
}
#endif

#endif // _RAPID_SDL_SURFACE_IOS_H_ 
