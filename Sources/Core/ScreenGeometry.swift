import AppKit
import Combine

public struct NotchMetrics {
    public let screenFrame: NSRect
    public let hasPhysicalNotch: Bool
    public let physicalWidth: CGFloat
    public let physicalHeight: CGFloat
    public let notchCenter: CGPoint
    public let notchRect: NSRect
}

public final class ScreenGeometryManager: ObservableObject {
    public static let shared = ScreenGeometryManager()
    
    @Published public private(set) var currentMetrics: NotchMetrics
    
    private init() {
        self.currentMetrics = ScreenGeometryManager.calculateMetrics()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenParametersChanged() {
        DispatchQueue.main.async {
            self.currentMetrics = ScreenGeometryManager.calculateMetrics()
        }
    }
    
    public static func calculateMetrics() -> NotchMetrics {
        guard let screen = NSScreen.main else {
            let defaultFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
            let defaultWidth: CGFloat = 220
            let defaultHeight: CGFloat = 38
            let center = CGPoint(x: defaultFrame.midX, y: defaultFrame.maxY)
            let rect = NSRect(x: center.x - defaultWidth / 2, y: defaultFrame.maxY - defaultHeight, width: defaultWidth, height: defaultHeight)
            return NotchMetrics(
                screenFrame: defaultFrame,
                hasPhysicalNotch: false,
                physicalWidth: defaultWidth,
                physicalHeight: defaultHeight,
                notchCenter: center,
                notchRect: rect
            )
        }
        
        let screenFrame = screen.frame
        var hasPhysicalNotch = false
        var notchWidth: CGFloat = 220.0
        var notchHeight: CGFloat = 38.0
        
        let topInset = screen.safeAreaInsets.top
        if topInset > 24.0 {
            hasPhysicalNotch = true
            notchHeight = topInset
            
            if let leftArea = screen.auxiliaryTopLeftArea,
               let rightArea = screen.auxiliaryTopRightArea {
                let measuredWidth = rightArea.minX - leftArea.maxX
                if measuredWidth > 100 {
                    notchWidth = measuredWidth
                }
            }
        } else {
            // Virtual notch on non-notch Macs or external monitors
            hasPhysicalNotch = false
            notchWidth = 200.0
            notchHeight = 34.0
        }
        
        let centerX = screenFrame.midX
        let topY = screenFrame.maxY
        let notchRect = NSRect(
            x: centerX - (notchWidth / 2.0),
            y: topY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
        
        return NotchMetrics(
            screenFrame: screenFrame,
            hasPhysicalNotch: hasPhysicalNotch,
            physicalWidth: notchWidth,
            physicalHeight: notchHeight,
            notchCenter: CGPoint(x: centerX, y: topY),
            notchRect: notchRect
        )
    }
}
