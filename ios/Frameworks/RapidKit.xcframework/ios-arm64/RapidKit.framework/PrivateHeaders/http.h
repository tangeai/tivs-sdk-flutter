#ifndef _RAPID_CORE_HTTP_REQ_ADAPTER_H_
#define _RAPID_CORE_HTTP_REQ_ADAPTER_H_

#ifdef __cplusplus
extern "C" {
#endif

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

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_HTTP_REQ_ADAPTER_H_
