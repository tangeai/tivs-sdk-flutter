#ifndef _RAPID_TOOLKIT_LOGGING_BRIDGE_H_
#define _RAPID_TOOLKIT_LOGGING_BRIDGE_H_

#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RAPID_LOG_UNKNOWN 0
#define RAPID_LOG_DEFAULT 1

#define RAPID_LOG_VERBOSE 2
#define RAPID_LOG_DEBUG 3
#define RAPID_LOG_INFO 4
#define RAPID_LOG_WARN 5
#define RAPID_LOG_ERROR 6
#define RAPID_LOG_FATAL 7
#define RAPID_LOG_SILENT 8

#define RAPID_LOG_TAG "RAPID"

void RAPID_Core_Logging_Print(const char* prefix, int level, const char* tag, const char* fmt, ...);

#define RAPID_LOG(level, tag, fmt, ...)                                      \
  do {                                                                       \
    RAPID_Core_Logging_Print(RAPID_LOG_TAG, level, tag, fmt, ##__VA_ARGS__); \
  } while (0)

#define RAPID_LOGV(tag, fmt, ...) RAPID_LOG(RAPID_LOG_VERBOSE, tag, fmt, ##__VA_ARGS__)
#define RAPID_LOGD(tag, fmt, ...) RAPID_LOG(RAPID_LOG_DEBUG, tag, fmt, ##__VA_ARGS__)
#define RAPID_LOGI(tag, fmt, ...) RAPID_LOG(RAPID_LOG_INFO, tag, fmt, ##__VA_ARGS__)
#define RAPID_LOGW(tag, fmt, ...) RAPID_LOG(RAPID_LOG_WARN, tag, fmt, ##__VA_ARGS__)
#define RAPID_LOGE(tag, fmt, ...) RAPID_LOG(RAPID_LOG_ERROR, tag, fmt, ##__VA_ARGS__)
#define RAPID_LOGF(tag, fmt, ...) RAPID_LOG(RAPID_LOG_FATAL, tag, fmt, ##__VA_ARGS__)
#define RAPID_LOGS(tag, fmt, ...) RAPID_LOG(RAPID_LOG_SILENT, tag, fmt, ##__VA_ARGS__)

void RAPID_Core_LeveledLoggingPrint(int level, const char* tag, const char* fmt);

void RAPID_Core_LeveledLoggingPrintWithPrefix(const char* prefix,
                                              int level,
                                              const char* tag,
                                              const char* fmt);

char* RAPID_Core_UploadLogging();

typedef void (*RAPID_Core_ConsoleLoggingFunc)(int level,
                                              const char* tag,
                                              const char* fmt,
                                              va_list args);
void RAPID_Core_SetConsoleLoggingFunc(RAPID_Core_ConsoleLoggingFunc func);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_TOOLKIT_LOGGING_BRIDGE_H_
