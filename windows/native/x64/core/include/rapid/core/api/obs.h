#ifndef _RAPID_OBS_API_H_
#define _RAPID_OBS_API_H_

// Docs: doc/explanation/designs/obs_observability_module.md

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  RAPID_Obs_Level_INFO = 0,
  RAPID_Obs_Level_WARN = 1,
  RAPID_Obs_Level_ERROR = 2
} RAPID_Obs_Level;

// ================================
// Observability Events
// ================================
//
// Notes:
// - This is the only event stream API for Studio Diagnostics and Workbench.
// - All returned strings are JSON.
// - Free returned strings with RAPID_Obs_FreeString.
//
// Pull events since the given seq (inclusive). The returned JSON is:
// {
//   "events": [
//     {
//       "seq": 1,
//       "ts_ms": 123,
//       "level": 0,
//       "device_id": "...",
//       "domain": "...",
//       "code": "...",
//       "summary": "...",
//       "context": { ... }
//     }
//   ],
//   "next_seq": 2,
//   "gap_detected": false
// }
char* RAPID_Obs_PullEvents(const char* device_id, long long since_seq);
void RAPID_Obs_FreeString(char* str);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_OBS_API_H_
