#ifndef _RAPID_CORE_OBSERVABILITY_H_
#define _RAPID_CORE_OBSERVABILITY_H_

#ifdef __cplusplus
extern "C" {
#endif

char* RAPID_Obs_PullEvents(const char* device_id, long long since_seq);
void RAPID_Obs_FreeString(char* str);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_OBSERVABILITY_H_
