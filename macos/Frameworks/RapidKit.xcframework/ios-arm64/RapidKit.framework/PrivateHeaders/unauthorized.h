#ifndef _RAPID_CORE_UNAUTHORIZED_H_
#define _RAPID_CORE_UNAUTHORIZED_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*RAPID_Core_UnauthorizedFunc)(void* user_context);

void RAPID_Core_Unauthorized_SetFunc(RAPID_Core_UnauthorizedFunc callback, void* user_context);

void RAPID_Core_Unauthorized_SetSendPort(long long port);

#ifdef __cplusplus
}
#endif

#endif  // _RAPID_CORE_UNAUTHORIZED_H_