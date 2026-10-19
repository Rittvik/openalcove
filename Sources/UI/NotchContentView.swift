import SwiftUI

public typealias NotchPillShape = AppleNotchPillShape

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
        if settings.hideWingsBehindNotch {
            return controller.isHovered ? notchW + 10 : notchW
        }
        if controller.isHovered {
            return notchW + 165
        }
        return notchW + 150
    }
    
    private var pillHeight: CGFloat {
        let notchH = geometry.currentMetrics.physicalHeight
        if controller.isExpanded {
            return 235
        }
        return notchH
    }
    
    public var body: some View {
        let metrics = geometry.currentMetrics
        let notchW = metrics.physicalWidth
        let notchH = metrics.physicalHeight
        let accentColor = Color(nsColor: .controlAccentColor)
        let isAccent = settings.useSystemAccentColor && controller.isExpanded
        let bottomRadius: CGFloat = controller.isExpanded ? 28 : 18
        
        ZStack(alignment: .top) {
            // Background pill hugging top bezel with Apple G2 squircle curvature & specular edge
            ZStack {
                // Pitch black backing to seamlessly blend into MacBook camera notch glass
                AppleNotchPillShape(bottomRadius: bottomRadius)
                    .fill(Color.black)
                
                // Subtle frosted system accent glow if enabled
                if isAccent {
                    AppleNotchPillShape(bottomRadius: bottomRadius)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.18), accentColor.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .overlay(
                // Apple-style specular edge highlight (ambient light reflection)
                AppleNotchPillShape(bottomRadius: bottomRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isAccent ? accentColor.opacity(0.45) : Color.white.opacity(controller.isExpanded ? 0.22 : 0.16),
                                isAccent ? accentColor.opacity(0.15) : Color.white.opacity(0.06),
                                isAccent ? accentColor.opacity(0.30) : Color.white.opacity(controller.isExpanded ? 0.14 : 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            // Multi-tier Apple shadow: sharp ambient occlusion + soft atmospheric drop
            .shadow(
                color: Color.black.opacity(controller.isExpanded ? 0.45 : 0.25),
                radius: controller.isExpanded ? 6 : 2.5,
                x: 0,
                y: controller.isExpanded ? 3 : 1.5
            )
            .shadow(
                color: isAccent ? accentColor.opacity(0.25) : Color.black.opacity(controller.isExpanded ? 0.55 : 0.20),
                radius: controller.isExpanded ? 24 : 8,
                x: 0,
                y: controller.isExpanded ? 12 : 4
            )
            .frame(width: pillWidth, height: pillHeight)
            
            // Content Container
            if controller.isExpanded {
                NotchExpandedView(onClose: {
                    controller.setExpanded(false)
                })
                .frame(width: 520, height: 235)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    )
                )
            } else {
                Button(action: {
                    controller.setExpanded(true)
                    SoundManager.shared.playHapticIfEnabled()
                }) {
                    NotchCompactView(
                        notchWidth: notchW,
                        notchHeight: notchH
                    )
                    .frame(width: pillWidth, height: notchH)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ApplePressableButtonStyle(scale: 0.985, pressedOpacity: 0.94))
                .onHover { hovering in
                    controller.handleHover(hovering)
                    if hovering {
                        SoundManager.shared.playHapticIfEnabled()
                    }
                }
            }
        }
        .frame(width: pillWidth, height: pillHeight, alignment: .top)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: controller.isExpanded)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: controller.isHovered)
    }
}
