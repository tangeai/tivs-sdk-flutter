import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Ensure a fixed window size, like iPhone 14.
    if let screen = NSScreen.main {
            let screenRect = screen.frame            
            let aspectRatio: CGFloat = 19.5 / 9.0        
            let windowHeight = screenRect.height * 0.8            
            let windowWidth = windowHeight / aspectRatio        
            let calculatedFrame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
            self.setFrame(calculatedFrame, display: true)          
            self.minSize = NSSize(width: windowWidth, height: windowHeight)
            self.maxSize = NSSize(width: windowWidth, height: windowHeight)
        }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
