part of 'library.dart';

class RapidNativeSDL {
  static Pointer<Void> createVoutSilence() {
    final ptr = apiCommonSdlSilenceBinding.RAPID_SDL_Vout_Silence_Create();
    return ptr.cast<Void>();
  }

  static Pointer<Void> createAoutSilence() {
    final ptr = apiCommonSdlSilenceBinding.RAPID_SDL_Aout_Silence_Create();
    return ptr.cast<Void>();
  }

  static Pointer<Void> createAoutSilenceWithInterval(int intervalMs) {
    final ptr = apiCommonSdlSilenceBinding.RAPID_SDL_Aout_Silence_Create_WithInterval(intervalMs);
    return ptr.cast<Void>();
  }
}
