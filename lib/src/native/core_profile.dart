part of 'library.dart';

Uint8List rapidNativeCreateBindingProfileWithHeader(String wifi, String pwd, String bindToken) {
  Uint8List? ret;

  Pointer<Utf8> wifiPtr = wifi.toNativeUtf8();
  Pointer<Utf8> pwdPtr = pwd.toNativeUtf8();
  Pointer<Utf8> bindTokenPtr = bindToken.toNativeUtf8();

  final ptr = coreApiProfileBinding.RAPID_Core_BindingProfileWithHeader(wifiPtr, pwdPtr, bindTokenPtr);
  if (ptr != nullptr && ptr.address != 0) {
    if (ptr.ref.length > 0 && ptr.ref.data != nullptr && ptr.ref.data.address != 0) {
      ret = Uint8List.fromList(ptr.ref.data.cast<Uint8>().asTypedList(ptr.ref.length));
    }
    coreApiProfileBinding.RAPID_Core_BindingProfile_ByteArray_Release(ptr);
  }

  calloc.free(wifiPtr);
  calloc.free(pwdPtr);
  calloc.free(bindTokenPtr);

  return ret ?? Uint8List(0);
}

String rapidNativeCreateBindingProfile(String wifi, String pwd, String bindToken) {
  Pointer<Utf8> wifiPtr = wifi.toNativeUtf8();
  Pointer<Utf8> pwdPtr = pwd.toNativeUtf8();
  Pointer<Utf8> bindTokenPtr = bindToken.toNativeUtf8();

  Pointer<Utf8> profilePtr = coreApiProfileBinding.RAPID_Core_BindingProfile_Create(wifiPtr, pwdPtr, bindTokenPtr);

  String ret = "";

  if (profilePtr != nullptr && profilePtr.address != 0) {
    ret = profilePtr.toDartString();
    coreApiProfileBinding.RAPID_Core_BindingProfile_Release(profilePtr);
  }

  calloc.free(wifiPtr);
  calloc.free(pwdPtr);
  calloc.free(bindTokenPtr);

  return ret;
}

void rapidNativeConfigureLocalNetworkBroadcastAddress(String address) {
  Pointer<Utf8> addressPtr = address.toNativeUtf8();
  coreApiLanBinding.RAPID_Core_LocalNetwork_SetBroadcastAddress(addressPtr);
  calloc.free(addressPtr);
}
