import SwiftUI

// MARK: - Apple G2 Continuous Curvature Notch Pill
public struct AppleNotchPillShape: Shape {
    public var bottomRadius: CGFloat = 16
    
    public var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }
    
    public init(bottomRadius: CGFloat = 16) {
        self.bottomRadius = bottomRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(bottomRadius, min(rect.width / 2, rect.height))
        // Apple continuous curvature factor (0.448 ratio approximates G2 continuity / squircle)
        let c: CGFloat = 0.448 * r
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        
        // Bottom-right continuous corner
        path.addCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - c),
            control2: CGPoint(x: rect.maxX - c, y: rect.maxY)
        )
        
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        
        // Bottom-left continuous corner
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control1: CGPoint(x: rect.minX + c, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - c)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Tactile Pressable Button Style (Apple WWDC Fluid Interface Principle: Kill Latency)
public struct ApplePressableButtonStyle: ButtonStyle {
    public var scale: CGFloat = 0.94
    public var pressedOpacity: CGFloat = 0.85
    
    public init(scale: CGFloat = 0.94, pressedOpacity: CGFloat = 0.85) {
        self.scale = scale
        self.pressedOpacity = pressedOpacity
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.80), value: configuration.isPressed)
    }
}

// MARK: - Apple macOS Control Center-Style Tactile Capsule Slider
public struct AppleControlSlider: View {
    @Binding public var value: Double // Range 0.0 ... 1.0
    public var iconName: String
    public var label: String
    public var tintColor: Color
    public var onEditingChanged: ((Double) -> Void)?
    
    @State private var isDragging: Bool = false
    
    public init(
        value: Binding<Double>,
        iconName: String,
        label: String,
        tintColor: Color = .white,
        onEditingChanged: ((Double) -> Void)? = nil
    ) {
        self._value = value
        self.iconName = iconName
        self.label = label
        self.tintColor = tintColor
        self.onEditingChanged = onEditingChanged
    }
    
    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let currentFillWidth = max(0, min(totalWidth, totalWidth * CGFloat(value)))
            
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                
                // Active Fill Pill
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tintColor.opacity(0.92))
                    .frame(width: max(0, currentFillWidth))
                
                // Track Overlays & Specular Border
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                
                // Foreground Content: Icon & Labels
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(value > 0.15 ? (tintColor == .white ? .black : .white) : .white.opacity(0.85))
                        .frame(width: 20)
                    
                    Text(label)
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(value > 0.35 ? (tintColor == .white ? .black.opacity(0.8) : .white) : .white.opacity(0.85))
                    
                    Spacer()
                    
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .default))
                        .monospacedDigit()
                        .foregroundColor(value > 0.85 ? (tintColor == .white ? .black.opacity(0.7) : .white) : .white.opacity(0.65))
                }
                .padding(.horizontal, 10)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(isDragging ? 1.015 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: isDragging)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let rawProgress = gesture.location.x / totalWidth
                        let clamped = min(1.0, max(0.0, Double(rawProgress)))
                        value = clamped
                        onEditingChanged?(clamped)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 28)
    }
}

// MARK: - Apple Control Center Style Quick Action Card Tile
public struct AppleActionTile: View {
    public var iconName: String
    public var title: String
    public var subtitle: String
    public var isActive: Bool
    public var activeColor: Color
    public var action: () -> Void
    
    public init(
        iconName: String,
        title: String,
        subtitle: String,
        isActive: Bool,
        activeColor: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.activeColor = activeColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? activeColor : Color.white.opacity(0.12))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isActive ? (activeColor == .white ? .black : .white) : .white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 10, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 9, weight: .regular, design: .default))
                        .foregroundColor(isActive ? activeColor : .white.opacity(0.45))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.10) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? activeColor.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(ApplePressableButtonStyle(scale: 0.96, pressedOpacity: 0.85))
    }
}
