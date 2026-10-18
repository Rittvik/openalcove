import SwiftUI

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
    
    private var isCompactActive: Bool {
        settings.compactMode && (
            media.hasActiveMedia ||
            volume.isHUDVisible ||
            brightness.isHUDVisible ||
            battery.isChargingHUDVisible ||
            bluetooth.isDeviceBannerVisible ||
            isHovered
        )
    }
    
    public var body: some View {
        let metrics = geometry.currentMetrics
        let notchW = metrics.physicalWidth
        let notchH = metrics.physicalHeight
        
        VStack(spacing: 0) {
            if isExpanded {
                NotchExpandedView(onClose: {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        isExpanded = false
                    }
                })
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85, anchor: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.9, anchor: .top).combined(with: .opacity)
                ))
            } else {
                // Notch Bar / Compact Live Island
                ZStack(alignment: .top) {
                    // Black notch base matching hardware notch
                    RoundedRectangle(cornerRadius: isCompactActive ? 18 : 10, style: .continuous)
                        .fill(Color.black)
                        .frame(
                            width: isCompactActive ? notchW + 80 : notchW,
                            height: isCompactActive ? notchH + 6 : notchH
                        )
                        .shadow(color: isCompactActive ? Color.black.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                    
                    if isCompactActive {
                        NotchCompactView(
                            notchWidth: notchW,
                            notchHeight: notchH
                        )
                        .frame(width: notchW + 80, height: notchH + 6)
                        .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        isHovered = hovering
                    }
                    if hovering && !isExpanded {
                        SoundManager.shared.play(.haptic)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        isExpanded.toggle()
                    }
                    SoundManager.shared.play(.haptic)
                }
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: isExpanded)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isCompactActive)
    }
}
