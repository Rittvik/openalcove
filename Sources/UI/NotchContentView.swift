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
    @ObservedObject var geometry = ScreenGeometryManager.shared
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    @ObservedObject var settings = AppSettings.shared
    
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    
    public init() {}
    
    private var pillWidth: CGFloat {
        let notchW = geometry.currentMetrics.physicalWidth
        if isExpanded {
            return 390
        }
        if isHovered {
            return notchW + 110
        }
        return notchW + 90
    }
    
    private var pillHeight: CGFloat {
        let notchH = geometry.currentMetrics.physicalHeight
        if isExpanded {
            return 200
        }
        return notchH
    }
    
    public var body: some View {
        let metrics = geometry.currentMetrics
        let notchW = metrics.physicalWidth
        let notchH = metrics.physicalHeight
        
        ZStack(alignment: .top) {
            // Background pill hugging the top bezel
            NotchPillShape(bottomRadius: isExpanded ? 24 : 16)
                .fill(Color.black)
                .overlay(
                    NotchPillShape(bottomRadius: isExpanded ? 24 : 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(
                    color: Color.black.opacity(isExpanded ? 0.6 : (isHovered ? 0.4 : 0.25)),
                    radius: isExpanded ? 16 : 8,
                    x: 0,
                    y: isExpanded ? 8 : 4
                )
                .frame(width: pillWidth, height: pillHeight)
            
            // Content
            if isExpanded {
                NotchExpandedView(onClose: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                })
                .frame(width: 390, height: 200)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            } else {
                NotchCompactView(
                    notchWidth: notchW,
                    notchHeight: notchH
                )
                .frame(width: pillWidth, height: notchH)
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        isHovered = hovering
                    }
                    if hovering {
                        SoundManager.shared.play(.haptic)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                    SoundManager.shared.play(.haptic)
                }
            }
        }
        .frame(width: pillWidth, height: pillHeight, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isHovered)
        .onChange(of: isExpanded) { expanded in
            NotchController.shared.setExpanded(expanded)
        }
    }
}
