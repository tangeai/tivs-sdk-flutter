#ifndef _RAPID_CORE_INSTRUCT_STANDARD_BRIDGE_H_
#define _RAPID_CORE_INSTRUCT_STANDARD_BRIDGE_H_

#ifdef __cplusplus
extern "C" {
#endif

enum RAPID_Core_InstructState {
  RAPID_Core_InstructState_RESPONSE_SUCCESS = 0,
  RAPID_Core_InstructState_TRANSPORT_UNAVAILABLE = 1,
  RAPID_Core_InstructState_RESPONSE_TIMEOUT = 2,
  RAPID_Core_InstructState_DUPLICATE_INSTRUCT = 3,
  RAPID_Core_InstructState_FAILED_INSTRUCT = 4,
  RAPID_Core_InstructState_UNKNOWN = 5,
  RAPID_Core_InstructState_DEVICE_IN_PROGRESS = 6,
  RAPID_Core_InstructState_DEVICE_ERROR_HEADER = 7,
  RAPID_Core_InstructState_DEVICE_UNSUPPORT_CMD = 8,
  RAPID_Core_InstructState_DEVICE_INVALID_PARAM = 9,
  RAPID_Core_InstructState_DEVICE_LACK_OF_RESOURCE = 10,
  RAPID_Core_InstructState_DEVICE_ERROR_INTERNAL = 11,
  RAPID_Core_InstructState_DEVICE_NOT_ALLOWED = 12,
};

typedef void* RAPID_Core_InstructStandard;

typedef void (*RAPID_Core_InstructStandard_ResponseFunc)(const char* json_str, int json_length, void* user_data);

RAPID_Core_InstructStandard RAPID_Core_InstructStandard_Create(void* pipe_proxy, RAPID_Core_InstructStandard_ResponseFunc func, void* user_data);
void RAPID_Core_InstructStandard_Request(RAPID_Core_InstructStandard instruct, const char* name, const char* params);
void RAPID_Core_InstructStandard_Release(RAPID_Core_InstructStandard instruct);
void RAPID_Core_InstructStandard_SetResponseSendPort(RAPID_Core_InstructStandard instruct, long long port);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_INSTRUCT_STANDARD_BRIDGE_H_
