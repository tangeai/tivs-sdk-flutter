#ifndef _RAPID_CORE_TOOL_MEMORY_H_
#define _RAPID_CORE_TOOL_MEMORY_H_

#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

char* RAPID_Core_Memory_Toolbox_AllocateCopy(const char* str);
void RAPID_Core_Memory_Toolbox_FreeCharPtr(char* ptr);

// allocates memory and make all bytes to zero
static inline void* RAPID_Core_mallocZ(size_t size) {
  void* ptr = malloc(size);
  if (ptr != NULL) {
    memset(ptr, 0, size);
  }
  return ptr;
}

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include <string>
#include <cstdint>

static inline std::string RAPID_Core_Memory_GetInstanceId(const void* ptr) {
  char buffer[32];
  snprintf(buffer, sizeof(buffer), "0x%lx", reinterpret_cast<std::uintptr_t>(ptr));
  return std::string(buffer);
}
#endif

#endif  //_RAPID_CORE_TOOL_MEMORY_H_
