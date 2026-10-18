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
        
        // Window level above menus, spaces and full screen apps (from Hopper decompilation)
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
    
    public private(set) var panel: NotchPanel?
    @Published public var isExpanded: Bool = false
    
    private init() {}
    
    public func start() {
        guard panel == nil else { return }
        
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        
        let windowWidth: CGFloat = 440
        let initialHeight: CGFloat = 50
        
        let rect = NSRect(
            x: centerX - (windowWidth / 2.0),
            y: topY - initialHeight,
            width: windowWidth,
            height: initialHeight
        )
        
        let newPanel = NotchPanel(contentRect: rect)
        let hostingView = NSHostingView(rootView: NotchRootView())
        newPanel.contentView = hostingView
        newPanel.orderFrontRegardless()
        
        self.panel = newPanel
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reposition()
        }
    }
    
    public func setExpanded(_ expanded: Bool) {
        self.isExpanded = expanded
        guard let panel = panel, let screen = NSScreen.main else { return }
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        let width: CGFloat = 440
        let height: CGFloat = expanded ? 230 : 50
        
        let rect = NSRect(
            x: centerX - (width / 2.0),
            y: topY - height,
            width: width,
            height: height
        )
        panel.setFrame(rect, display: true, animate: false)
    }
    
    public func reposition() {
        setExpanded(isExpanded)
    }
}

public struct NotchRootView: View {
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            NotchContentView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .edgesIgnoringSafeArea(.all)
    }
}
