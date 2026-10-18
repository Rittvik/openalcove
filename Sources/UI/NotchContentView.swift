import SwiftUI

public struct NotchPillShape: Shape {
    public var bottomRadius: CGFloat = 14
    
    public init(bottomRadius: CGFloat = 14) {
        self.bottomRadius = bottomRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

public struct NotchContentView: View {
    @ObservedObject var controller = NotchController.shared
    @ObservedObject var geometry = ScreenGeometryManager.shared
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    @ObservedObject var settings = AppSettings.shared
    
    public init() {}
    
    private var pillWidth: CGFloat {
        let notchW = geometry.currentMetrics.physicalWidth
        if controller.isExpanded {
            return 520
        }
        if controller.isHovered {
            return notchW + 125
        }
        return notchW + 110
    }
    
    private var pillHeight: CGFloat {
        let notchH = geometry.currentMetrics.physicalHeight
        if controller.isExpanded {
            return 210
        }
        return notchH
    }
    
    public var body: some View {
        let metrics = geometry.currentMetrics
        let notchW = metrics.physicalWidth
        let notchH = metrics.physicalHeight
        
        ZStack(alignment: .top) {
            // Background pill hugging the top bezel
            NotchPillShape(bottomRadius: controller.isExpanded ? 26 : 16)
                .fill(Color.black)
                .overlay(
                    NotchPillShape(bottomRadius: controller.isExpanded ? 26 : 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(
                    color: Color.black.opacity(controller.isExpanded ? 0.65 : (controller.isHovered ? 0.45 : 0.3)),
                    radius: controller.isExpanded ? 18 : 8,
                    x: 0,
                    y: controller.isExpanded ? 10 : 4
                )
                .frame(width: pillWidth, height: pillHeight)
            
            // Content
            if controller.isExpanded {
                NotchExpandedView(onClose: {
                    controller.setExpanded(false)
                })
                .frame(width: 520, height: 210)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                NotchCompactView(
                    notchWidth: notchW,
                    notchHeight: notchH
                )
                .frame(width: pillWidth, height: notchH)
                .contentShape(Rectangle())
                .onHover { hovering in
                    controller.handleHover(hovering)
                    if hovering {
                        SoundManager.shared.play(.haptic)
                    }
                }
                .onTapGesture {
                    controller.setExpanded(true)
                    SoundManager.shared.play(.haptic)
                }
            }
        }
        .frame(width: pillWidth, height: pillHeight, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.isExpanded)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: controller.isHovered)
        .onHover { hovering in
            controller.handleHover(hovering)
        }
    }
}
