#ifndef _RAPID_CORE_EXTERNAL_DATA_H_
#define _RAPID_CORE_EXTERNAL_DATA_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void* RAPID_Core_PipeProxy;
typedef void* RAPID_Core_LiveStream;

typedef void (*RAPID_Core_ExternalUserDataFunc)(unsigned int data1,
                                                unsigned int data2,
                                                const char* buffer,
                                                int buffer_size,
                                                void* user_context);

typedef void (*RAPID_Core_TypedExternalUserDataFunc)(unsigned int type,
                                                     unsigned int data1,
                                                     unsigned int data2,
                                                     const char* buffer,
                                                     int buffer_size,
                                                     void* user_context);

void RAPID_Core_Instruct_SetUserExternalDataFunc(RAPID_Core_PipeProxy proxy,
                                                 RAPID_Core_ExternalUserDataFunc func,
                                                 void* user_context);

void RAPID_Core_Instruct_SetTypedUserExternalDataFunc(RAPID_Core_PipeProxy proxy,
                                                      RAPID_Core_TypedExternalUserDataFunc func,
                                                      void* user_context);

void RAPID_Core_Instruct_SetUserExternalDataSendPort(RAPID_Core_PipeProxy proxy,
                                                     long long port);

void RAPID_Core_LiveStream_SetUserExternalDataFunc(RAPID_Core_LiveStream live_stream,
                                                   RAPID_Core_ExternalUserDataFunc func,
                                                   void* user_context);

void RAPID_Core_LiveStream_SetTypedUserExternalDataFunc(RAPID_Core_LiveStream live_stream,
                                                        RAPID_Core_TypedExternalUserDataFunc func,
                                                        void* user_context);

void RAPID_Core_LiveStream_SetUserExternalDataSendPort(RAPID_Core_LiveStream live_stream,
                                                       long long port);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_EXTERNAL_DATA_H_
