#ifndef _RAPID_CORE_HTTP_REQ_ADAPTER_H_
#define _RAPID_CORE_HTTP_REQ_ADAPTER_H_

#ifdef __cplusplus
extern "C" {
#endif

enum RAPID_Core_HttpMethod {
    RAPID_Core_HttpMethod_GET = 0,
    RAPID_Core_HttpMethod_POST = 1,
    RAPID_Core_HttpMethod_DELETE = 2,
    RAPID_Core_HttpMethod_PATCH = 3
};

typedef struct RAPID_Core_HttpResp {
  char* data;
  int success;
  char* message;
  int code;
} RAPID_Core_HttpResp;

struct RAPID_Core_HttpResp* RAPID_Core_HttpRequest(char* path, int method, char* request_content);
struct RAPID_Core_HttpResp* RAPID_Core_HttpRequestWithHeaders(char* path,
                                                              int method,
                                                              char* request_content,
                                                              char* request_headers);
void RAPID_Core_HttpResp_Free(struct RAPID_Core_HttpResp* resp);

void RAPID_Core_Http_LoggingEnable(int enable);

char* RAPID_Core_Http_DebugGetCapturedListJson(void);
void RAPID_Core_Http_DebugFree(char* json);
void RAPID_Core_Http_DebugEnable(int enable);
void RAPID_Core_Http_DebugClear(void);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_HTTP_REQ_ADAPTER_H_
