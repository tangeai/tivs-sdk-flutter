#ifndef _RAPID_CORE_BINDING_PROFILE_H_
#define _RAPID_CORE_BINDING_PROFILE_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RAPID_Core_BindingProfile_ByteArray {
    char *data;
    int length;
} RAPID_Core_BindingProfile_ByteArray;

char* RAPID_Core_BindingProfile_Create(const char *wifi, const char *pwd, const char *bindToken);
RAPID_Core_BindingProfile_ByteArray* RAPID_Core_BindingProfileWithHeader(const char *wifi, const char *pwd, const char *bindToken);
void RAPID_Core_BindingProfile_Release(char *profile);
void RAPID_Core_BindingProfile_ByteArray_Release(RAPID_Core_BindingProfile_ByteArray* byte_array);

#ifdef __cplusplus
}
#endif

#endif  //_RAPID_CORE_BINDING_PROFILE_H_
