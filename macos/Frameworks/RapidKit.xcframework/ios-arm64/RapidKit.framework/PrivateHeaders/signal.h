#ifndef _RAPID_SIGNAL_HANDLER_H_
#define _RAPID_SIGNAL_HANDLER_H_

#ifdef __cplusplus
extern "C" {
#endif

extern char* previous_crash_detail;
extern int previous_crash_detail_length;

void RAPID_Core_RegisterSignalHandler();

#ifdef __cplusplus
}
#endif

#endif // _RAPID_SIGNAL_HANDLER_H_