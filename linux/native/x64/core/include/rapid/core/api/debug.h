#ifndef _RAPID_CORE_DEBUGGING_CODE_H_
#define _RAPID_CORE_DEBUGGING_CODE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_Core_AuthResp RAPID_Core_AuthResp;

char* RAPID_Core_DebuggingCode_Create();
void RAPID_Core_DebuggingCode_Free(char* code);
RAPID_Core_AuthResp* RAPID_Core_DebuggingCode_Apply(const char* code);
int RAPID_Core_CheckInternetConnectivity();

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_DEBUGGING_CODE_H_
