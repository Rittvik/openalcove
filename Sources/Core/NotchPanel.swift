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
        self.acceptsMouseMovedEvents = true
    }
    
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}

public final class HoverTrackingHostingView<Content: View>: NSHostingView<Content> {
    private var trackingArea: NSTrackingArea?
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .activeAlways,
            .inVisibleRect
        ]
        let newArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        self.trackingArea = newArea
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        let pt = convert(event.locationInWindow, from: nil)
        NotchController.shared.handleHover(true, point: pt)
    }
    
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let pt = convert(event.locationInWindow, from: nil)
        NotchController.shared.handleHover(true, point: pt)
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NotchController.shared.handleHover(false)
    }
}

public final class NotchController: ObservableObject {
    public static let shared = NotchController()
    
    public private(set) var panel: NotchPanel?
    @Published public var isExpanded: Bool = false
    @Published public var isHovered: Bool = false
    
    private var expandWorkItem: DispatchWorkItem?
    private var collapseWorkItem: DispatchWorkItem?
    
    private init() {}
    
    public func collapsedWidth(for metrics: NotchMetrics) -> CGFloat {
        AppSettings.shared.hideWingsBehindNotch ? metrics.physicalWidth : (metrics.physicalWidth + 150)
    }
    
    public func start() {
        guard panel == nil else { return }
        
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        
        let metrics = ScreenGeometryManager.shared.currentMetrics
        let initialWidth: CGFloat = collapsedWidth(for: metrics)
        let initialHeight: CGFloat = metrics.physicalHeight
        
        let rect = NSRect(
            x: centerX - (initialWidth / 2.0),
            y: topY - initialHeight,
            width: initialWidth,
            height: initialHeight
        )
        
        let newPanel = NotchPanel(contentRect: rect)
        let hostingView = HoverTrackingHostingView(rootView: NotchRootView())
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
    
    public func handleHover(_ hovering: Bool, point: NSPoint? = nil) {
        if hovering {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            
            // If already expanded, stay expanded
            if isExpanded {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    self.isHovered = true
                }
                return
            }
            
            // Check if cursor point is strictly inside the visible notch pill bounds
            if let pt = point, let panel = panel {
                let metrics = ScreenGeometryManager.shared.currentMetrics
                let pillWidth: CGFloat = collapsedWidth(for: metrics)
                let pillHeight: CGFloat = metrics.physicalHeight
                let bounds = panel.contentView?.bounds ?? .zero
                let pillRect = NSRect(
                    x: (bounds.width - pillWidth) / 2.0,
                    y: bounds.height - pillHeight,
                    width: pillWidth,
                    height: pillHeight
                )
                // Reject hover events that fall outside the visible notch pill
                guard pillRect.contains(pt) else {
                    expandWorkItem?.cancel()
                    expandWorkItem = nil
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        self.isHovered = false
                    }
                    return
                }
            }
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                self.isHovered = true
            }
            
            // Require mouse to intentionally dwell inside the notch for 0.20s before expanding
            if expandWorkItem == nil && !isExpanded {
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self, self.isHovered, !self.isExpanded else { return }
                    self.setExpanded(true)
                }
                self.expandWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20, execute: workItem)
            }
        } else {
            expandWorkItem?.cancel()
            expandWorkItem = nil
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                self.isHovered = false
            }
            
            // Debounce collapse by 0.40s so accidental cursor slip doesn't snap notch shut
            collapseWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.isExpanded {
                    self.setExpanded(false)
                }
            }
            collapseWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40, execute: workItem)
        }
    }
    
    public func setExpanded(_ expanded: Bool) {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        
        if expanded {
            expandWorkItem?.cancel()
            expandWorkItem = nil
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            
            let width: CGFloat = 560
            let height: CGFloat = 260
            let rect = NSRect(
                x: centerX - (width / 2.0),
                y: topY - height,
                width: width,
                height: height
            )
            // Expand window frame first so animation has room
            panel.setFrame(rect, display: true, animate: false)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.isExpanded = true
            }
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                self.isExpanded = false
            }
            
            // Shrink window after pill animation completes to avoid clipping
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self, !self.isExpanded, let panel = self.panel, let screen = NSScreen.main else { return }
                let metrics = ScreenGeometryManager.shared.currentMetrics
                let width: CGFloat = self.collapsedWidth(for: metrics)
                let height: CGFloat = metrics.physicalHeight
                let rect = NSRect(
                    x: screen.frame.midX - (width / 2.0),
                    y: screen.frame.maxY - height,
                    width: width,
                    height: height
                )
                panel.setFrame(rect, display: true, animate: false)
            }
        }
    }
    
    public func reposition() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let topY = screen.frame.maxY
        let centerX = screen.frame.midX
        let metrics = ScreenGeometryManager.shared.currentMetrics
        
        let width: CGFloat = isExpanded ? 560 : collapsedWidth(for: metrics)
        let height: CGFloat = isExpanded ? 260 : metrics.physicalHeight
        
        let rect = NSRect(
            x: centerX - (width / 2.0),
            y: topY - height,
            width: width,
            height: height
        )
        panel.setFrame(rect, display: true, animate: false)
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
