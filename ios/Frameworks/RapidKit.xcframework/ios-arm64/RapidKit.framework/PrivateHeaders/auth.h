#ifndef _RAPID_CORE_AUTHENTICATE_ADAPTER_H_
#define _RAPID_CORE_AUTHENTICATE_ADAPTER_H_

#ifdef __cplusplus
extern "C" {
#endif

struct RAPID_Core_AuthResp {
  int user_id;
  int issue_at;
  int expires_in;
  int success;
  char* message;
  int code;
};

struct RAPID_Core_AuthResp* RAPID_Core_Authenticate(const char* access_token);

char* RAPID_Core_AccessToken_Copy(void);

void RAPID_Core_AccessToken_Free(char* access_token);

void RAPID_Core_AuthResp_Free(struct RAPID_Core_AuthResp* resp);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_AUTHENTICATE_ADAPTER_H_
