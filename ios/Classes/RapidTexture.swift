import Flutter
import AVFoundation
import RapidKit

class RapidTexture: NSObject, FlutterTexture {
    var textureId: Int64 = 0
    var flutterTextureRegistry: FlutterTextureRegistry?
    private var pixelBuffer: CVPixelBuffer?

    private var lastOverlay: UnsafeMutablePointer<RAPID_SDL_VoutOverlay_CVPixelBuffer>?
    
    func dispose() {
        if let lastOverlay = self.lastOverlay {
            RAPID_SDL_VoutOverlay_CVPixelBuffer_Free(lastOverlay)
            self.lastOverlay = nil
        }
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }        
        return Unmanaged.passRetained(pixelBuffer)
    }
    
    private static let callback: @convention(c) (UnsafeMutablePointer<RAPID_SDL_VoutOverlay_CVPixelBuffer>?, UnsafeMutableRawPointer?) -> Int32 = { (overlay, context) in
        guard let context = context, overlay != nil else {
            if let overlay = overlay {
                RAPID_SDL_VoutOverlay_CVPixelBuffer_Free(overlay)
            }
            print("Callback called with invalid arguments")
            return 0
        }
    
        let mySelf = Unmanaged<RapidTexture>.fromOpaque(context).takeUnretainedValue()
        mySelf.logOverlayPointer(overlay)
        
        return 1
    }
    
    func getCFunctionPointer() -> (DisplayCVPixelBufferFunc?, UnsafeMutableRawPointer?) {
        let context = Unmanaged.passUnretained(self).toOpaque()
        return (RapidTexture.callback, UnsafeMutableRawPointer(context))
    }
    
    private func logOverlayPointer(_ overlay: UnsafeMutablePointer<RAPID_SDL_VoutOverlay_CVPixelBuffer>?) {
        
        if (overlay != nil) {
                        
            if let lastOverlay = self.lastOverlay {
                RAPID_SDL_VoutOverlay_CVPixelBuffer_Free(lastOverlay)
            }
            
            if let unmanagedPixelBuffer = overlay?.pointee.pixel_buffer {
                self.pixelBuffer = unsafeBitCast(unmanagedPixelBuffer, to: CVPixelBuffer.self)
                self.lastOverlay = overlay
                flutterTextureRegistry?.textureFrameAvailable(self.textureId)
            } else {
                self.pixelBuffer = nil
                self.lastOverlay = nil
            }
        }
    }
}
