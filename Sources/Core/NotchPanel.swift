import AppKit
import SwiftUI

public final class NotchPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.hasShadow = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.isMovable = false
        self.isReleasedWhenClosed = false
        self.canBecomeVisibleWithoutLogin = true
        self.animationBehavior = .none
        
        // Window level above menus, spaces and full screen apps
        self.level = NSWindow.Level(Int(CGShieldingWindowLevel()) + 1)
        
        // canJoinAllSpaces | stationary | ignoresCycle | fullScreenAuxiliary (0x151 from Hopper decompilation)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.ignoresMouseEvents = false
    }
    
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}

public final class NotchController: ObservableObject {
    public static let shared = NotchController()
    
    private var panel: NotchPanel?
    
    private init() {}
    
    public func start() {
        guard panel == nil else { return }
        
        let windowWidth: CGFloat = 440
        let windowHeight: CGFloat = 280
        
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        
        let rect = NSRect(
            x: centerX - (windowWidth / 2.0),
            y: topY - windowHeight,
            width: windowWidth,
            height: windowHeight
        )
        
        let newPanel = NotchPanel(contentRect: rect)
        let hostingView = NSHostingView(rootView: NotchContentView())
        newPanel.contentView = hostingView
        newPanel.orderFrontRegardless()
        
        self.panel = newPanel
        
        // Reposition on screen parameter change
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reposition()
        }
    }
    
    public func reposition() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let windowWidth: CGFloat = 440
        let windowHeight: CGFloat = 280
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        
        let rect = NSRect(
            x: centerX - (windowWidth / 2.0),
            y: topY - windowHeight,
            width: windowWidth,
            height: windowHeight
        )
        panel.setFrame(rect, display: true)
    }
}
