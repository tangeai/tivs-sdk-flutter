part of 'library.dart';

DynamicLibrary? _libRapidCore;
DynamicLibrary get libRapidCore {
  if (_libRapidCore == null) {
    if (Platform.isAndroid) {
      _libRapidCore = DynamicLibrary.open('libRapidCore.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      _libRapidCore = DynamicLibrary.process();
    } else if (Platform.isWindows) {
      _libRapidCore = DynamicLibrary.open('libRapidCore.dll');
    } else {
      _libRapidCore = DynamicLibrary.open('libRapidCore.so');
    }
  }
  return _libRapidCore!;
}

DynamicLibrary? _libRapidMedia;
DynamicLibrary get libRapidMedia {
  if (_libRapidMedia == null) {
    if (Platform.isAndroid) {
      _libRapidMedia = DynamicLibrary.open('libRapidMedia.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      _libRapidMedia = DynamicLibrary.process();
    } else if (Platform.isWindows) {
      _libRapidMedia = DynamicLibrary.open('libRapidMedia.dll');
    } else {
      _libRapidMedia = DynamicLibrary.open('libRapidMedia.so');
    }
  }
  return _libRapidMedia!;
}

CoreApiAuthBinding? _coreApiAuthBinding;
CoreApiAuthBinding get coreApiAuthBinding {
  _coreApiAuthBinding ??= CoreApiAuthBinding(libRapidCore);
  return _coreApiAuthBinding!;
}

CoreApiChatBinding? _coreApiChatBinding;
CoreApiChatBinding get coreApiChatBinding {
  _coreApiChatBinding ??= CoreApiChatBinding(libRapidCore);
  return _coreApiChatBinding!;
}

CoreApiDebugBinding? _coreApiDebugBinding;
CoreApiDebugBinding get coreApiDebugBinding {
  _coreApiDebugBinding ??= CoreApiDebugBinding(libRapidCore);
  return _coreApiDebugBinding!;
}

CoreApiPersistentBinding? _coreApiPersistentBinding;
CoreApiPersistentBinding get coreApiPersistentBinding {
  _coreApiPersistentBinding ??= CoreApiPersistentBinding(libRapidCore);
  return _coreApiPersistentBinding!;
}

CoreApiDartBinding? _coreApiDartBinding;
CoreApiDartBinding get coreApiDartBinding {
  _coreApiDartBinding ??= CoreApiDartBinding(libRapidCore);
  return _coreApiDartBinding!;
}

CoreApiExternalBinding? _coreApiExternalBinding;
CoreApiExternalBinding get coreApiExternalBinding {
  _coreApiExternalBinding ??= CoreApiExternalBinding(libRapidCore);
  return _coreApiExternalBinding!;
}

CoreApiInitializeBinding? _coreApiInitializeBinding;
CoreApiInitializeBinding get coreApiInitializeBinding {
  _coreApiInitializeBinding ??= CoreApiInitializeBinding(libRapidCore);
  return _coreApiInitializeBinding!;
}

CoreApiTransmitBinding? _coreApiTransmitBinding;
CoreApiTransmitBinding get coreApiTransmitBinding {
  _coreApiTransmitBinding ??= CoreApiTransmitBinding(libRapidCore);
  return _coreApiTransmitBinding!;
}

CoreApiHttpBinding? _coreApiHttpBinding;
CoreApiHttpBinding get coreApiHttpBinding {
  _coreApiHttpBinding ??= CoreApiHttpBinding(libRapidCore);
  return _coreApiHttpBinding!;
}

CoreApiInstructBinding? _coreApiInstructBinding;
CoreApiInstructBinding get coreApiInstructBinding {
  _coreApiInstructBinding ??= CoreApiInstructBinding(libRapidCore);
  return _coreApiInstructBinding!;
}

CoreApiLanBinding? _coreApiLanBinding;
CoreApiLanBinding get coreApiLanBinding {
  _coreApiLanBinding ??= CoreApiLanBinding(libRapidCore);
  return _coreApiLanBinding!;
}

CoreApiLogBinding? _coreApiLogBinding;
CoreApiLogBinding get coreApiLogBinding {
  _coreApiLogBinding ??= CoreApiLogBinding(libRapidCore);
  return _coreApiLogBinding!;
}

CoreApiMemoryBinding? _coreApiMemoryBinding;
CoreApiMemoryBinding get coreApiMemoryBinding {
  _coreApiMemoryBinding ??= CoreApiMemoryBinding(libRapidCore);
  return _coreApiMemoryBinding!;
}

CoreApiObsBinding? _coreApiObsBinding;
CoreApiObsBinding get coreApiObsBinding {
  _coreApiObsBinding ??= CoreApiObsBinding(libRapidCore);
  return _coreApiObsBinding!;
}

CoreApiPipeBinding? _coreApiPipeBinding;
CoreApiPipeBinding get coreApiPipeBinding {
  _coreApiPipeBinding ??= CoreApiPipeBinding(libRapidCore);
  return _coreApiPipeBinding!;
}

CoreApiProfileBinding? _coreApiProfileBinding;
CoreApiProfileBinding get coreApiProfileBinding {
  _coreApiProfileBinding ??= CoreApiProfileBinding(libRapidCore);
  return _coreApiProfileBinding!;
}

CoreApiStreamBinding? _coreApiStreamBinding;
CoreApiStreamBinding get coreApiStreamBinding {
  _coreApiStreamBinding ??= CoreApiStreamBinding(libRapidCore);
  return _coreApiStreamBinding!;
}

MediaApiChatBinding? _mediaApiChatBinding;
MediaApiChatBinding get mediaApiChatBinding {
  _mediaApiChatBinding ??= MediaApiChatBinding(libRapidMedia);
  return _mediaApiChatBinding!;
}

MediaApiPlayerBinding? _mediaApiPlayerBinding;
MediaApiPlayerBinding get mediaApiPlayerBinding {
  _mediaApiPlayerBinding ??= MediaApiPlayerBinding(libRapidMedia);
  return _mediaApiPlayerBinding!;
}

MediaApiCaptureBinding? _mediaApiCaptureBinding;
MediaApiCaptureBinding get mediaApiCaptureBinding {
  _mediaApiCaptureBinding ??= MediaApiCaptureBinding(libRapidMedia);
  return _mediaApiCaptureBinding!;
}

CoreApiUnauthorizedBinding? _coreApiUnauthorizedBinding;
CoreApiUnauthorizedBinding get coreApiUnauthorizedBinding {
  _coreApiUnauthorizedBinding ??= CoreApiUnauthorizedBinding(libRapidCore);
  return _coreApiUnauthorizedBinding!;
}

ApiCommonSdl_silenceBinding? _apiCommonSdlSilenceBinding;
ApiCommonSdl_silenceBinding get apiCommonSdlSilenceBinding {
  _apiCommonSdlSilenceBinding ??= ApiCommonSdl_silenceBinding(libRapidCore);
  return _apiCommonSdlSilenceBinding!;
}
