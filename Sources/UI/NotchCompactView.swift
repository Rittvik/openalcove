import SwiftUI
import Combine

public struct NotchCompactView: View {
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    @ObservedObject var settings = AppSettings.shared
    
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    
    @State private var currentTime: String = ""
    private let clockTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init(notchWidth: CGFloat, notchHeight: CGFloat) {
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        _currentTime = State(initialValue: NotchCompactView.formattedCurrentTime())
    }
    
    public var body: some View {
        Group {
            if settings.hideWingsBehindNotch {
                // Invisible during collapsed idle in stealth mode
                Color.clear
                    .frame(width: notchWidth, height: notchHeight)
            } else {
                HStack(spacing: 0) {
                    // MARK: - Left Wing (Source Indicator)
                    HStack(spacing: 6) {
                        if volume.isHUDVisible {
                            Image(systemName: volume.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        } else if brightness.isHUDVisible {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.yellow)
                        } else if battery.isChargingHUDVisible {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        } else if bluetooth.isDeviceBannerVisible {
                            Image(systemName: "airpodspro")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        } else if media.hasActiveMedia && media.track.isPlaying {
                            if let artwork = media.track.artwork {
                                Image(nsImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 19, height: 19)
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                            } else {
                                Image(systemName: "music.note")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                            }
                        } else {
                            // Idle: SF Pro Time with monospaced digits
                            Text(currentTime)
                                .font(.system(size: 11.5, weight: .semibold, design: .default))
                                .monospacedDigit()
                                .lineLimit(1)
                                .fixedSize()
                                .foregroundColor(.white.opacity(0.92))
                        }
                    }
                    .frame(width: 66, alignment: .leading)
                    .padding(.leading, 13)
                    
                    // Hardware notch clearance spacer
                    Spacer()
                        .frame(minWidth: max(0, notchWidth - 96))
                    
                    // MARK: - Right Wing (Level / Status Indicator)
                    HStack(spacing: 5) {
                        if volume.isHUDVisible {
                            // Mini Apple Dynamic Island Volume Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.20))
                                    Capsule().fill(Color.white)
                                        .frame(width: max(0, geo.size.width * CGFloat(volume.volume)))
                                        .animation(.spring(response: 0.22, dampingFraction: 0.82), value: volume.volume)
                                }
                            }
                            .frame(width: 48, height: 5)
                        } else if brightness.isHUDVisible {
                            // Mini Brightness Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.20))
                                    Capsule().fill(Color.yellow)
                                        .frame(width: max(0, geo.size.width * CGFloat(brightness.brightness)))
                                        .animation(.spring(response: 0.22, dampingFraction: 0.82), value: brightness.brightness)
                                }
                            }
                            .frame(width: 48, height: 5)
                        } else if battery.isChargingHUDVisible {
                            HStack(spacing: 3) {
                                Text("\(battery.batteryPercentage)%")
                                    .font(.system(size: 11, weight: .semibold, design: .default))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .fixedSize()
                                    .foregroundColor(.green)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        } else if bluetooth.isDeviceBannerVisible {
                            Text("AirPods")
                                .font(.system(size: 10, weight: .semibold, design: .default))
                                .lineLimit(1)
                                .fixedSize()
                                .foregroundColor(.white.opacity(0.92))
                        } else if media.hasActiveMedia && media.track.isPlaying {
                            WaveformView(
                                isPlaying: true,
                                barCount: 4,
                                activeColor: Color(red: 0.12, green: 0.84, blue: 0.38),
                                maxHeight: 11
                            )
                        } else {
                            // Idle: Monospaced Battery Percentage & Gauge
                            HStack(spacing: 3.5) {
                                Text("\(battery.batteryPercentage)%")
                                    .font(.system(size: 11, weight: .semibold, design: .default))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .fixedSize()
                                    .foregroundColor(battery.batteryPercentage < 20 ? .red : .white.opacity(0.85))
                                
                                Image(systemName: battery.isCharging ? "battery.100.bolt" : batteryIconName(for: battery.batteryPercentage))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(battery.isCharging ? .green : (battery.batteryPercentage < 20 ? .red : .white.opacity(0.85)))
                            }
                        }
                    }
                    .frame(width: 66, alignment: .trailing)
                    .padding(.trailing, 13)
                }
                .frame(height: notchHeight)
            }
        }
        .onReceive(clockTimer) { _ in
            currentTime = NotchCompactView.formattedCurrentTime()
        }
    }
    
    private static func formattedCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    private func batteryIconName(for percent: Int) -> String {
        if percent > 80 { return "battery.100" }
        if percent > 50 { return "battery.75" }
        if percent > 25 { return "battery.50" }
        if percent > 10 { return "battery.25" }
        return "battery.0"
    }
}
