#ifndef _RAPID_CORE_INITIALIZE_ADAPTER_H_
#define _RAPID_CORE_INITIALIZE_ADAPTER_H_

#ifdef __cplusplus
extern "C" {
#endif

int RAPID_Core_Initialize(const char* app_id, const char* package_name, const char* platform,
                          const char* language, int environment, const char* logging_cache_directory, int console_logging);

char* RAPID_Core_VersionName();
char* RAPID_Core_BuildId();
char* RAPID_Core_CommitHash();
char* RAPID_Core_AppId();
char* RAPID_Core_PackageName();

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_INITIALIZE_ADAPTER_H_