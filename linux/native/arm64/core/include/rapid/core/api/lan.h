#ifndef _RAPID_CORE_LAN_SCANNER_BRIDGE_H_
#define _RAPID_CORE_LAN_SCANNER_BRIDGE_H_


#ifdef __cplusplus
extern "C" {
#endif

void RAPID_Core_LocalNetwork_SetBroadcastAddress(const char* address);


typedef void* RAPID_Core_LanScanner;
RAPID_Core_LanScanner RAPID_Core_LanScanner_Create();
void RAPID_Core_LanScanner_Destroy(RAPID_Core_LanScanner scanner);
char* RAPID_Core_LanScanner_FoundDevices(RAPID_Core_LanScanner scanner);
void RAPID_Core_LanScanner_Start(RAPID_Core_LanScanner scanner);
void RAPID_Core_LanScanner_Stop(RAPID_Core_LanScanner scanner);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_LAN_SCANNER_BRIDGE_H_
