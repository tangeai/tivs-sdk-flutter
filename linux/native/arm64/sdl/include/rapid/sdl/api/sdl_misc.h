#ifndef _RAPID_SDL_MISC_H_
#define _RAPID_SDL_MISC_H_

#include <memory.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RAPID_MAX(a, b) ((a) > (b) ? (a) : (b))
#define RAPID_MAX3(a, b, c) RAPID_MAX(RAPID_MAX(a, b), c)
#define RAPID_MIN(a, b) ((a) > (b) ? (b) : (a))
#define RAPID_MIN3(a, b, c) RAPID_MIN(RAPID_MIN(a, b), c)

inline static void* RAPID_mallocz(size_t size) {
  void* mem = malloc(size);
  if (!mem) return mem;

  memset(mem, 0, size);
  return mem;
}

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_SDL_MISC_H_
