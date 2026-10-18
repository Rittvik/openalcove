import SwiftUI
import Combine

public struct NotchCompactView: View {
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    
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
        HStack(spacing: 0) {
            // MARK: - Left Wing
            HStack(spacing: 6) {
                if volume.isHUDVisible {
                    Image(systemName: volume.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                } else if brightness.isHUDVisible {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                } else if battery.isChargingHUDVisible {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                } else if bluetooth.isDeviceBannerVisible {
                    Image(systemName: "airpodspro")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                } else if media.hasActiveMedia && media.track.isPlaying {
                    if let artwork = media.track.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38)) // Spotify green
                    }
                } else {
                    // Idle: Show Time
                    Text(currentTime)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(width: 48, alignment: .leading)
            .padding(.leading, 10)
            
            // Gap for the hardware notch camera
            Spacer()
                .frame(minWidth: max(0, notchWidth - 96))
            
            // MARK: - Right Wing
            HStack(spacing: 5) {
                if volume.isHUDVisible {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))
                            Capsule().fill(Color.white)
                                .frame(width: geo.size.width * CGFloat(volume.volume))
                        }
                    }
                    .frame(width: 42, height: 4)
                } else if brightness.isHUDVisible {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))
                            Capsule().fill(Color.yellow)
                                .frame(width: geo.size.width * CGFloat(brightness.brightness))
                        }
                    }
                    .frame(width: 42, height: 4)
                } else if battery.isChargingHUDVisible {
                    HStack(spacing: 2) {
                        Text("\(battery.batteryPercentage)%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    }
                } else if bluetooth.isDeviceBannerVisible {
                    Text("AirPods")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                } else if media.hasActiveMedia && media.track.isPlaying {
                    WaveformView(
                        isPlaying: true,
                        barCount: 4,
                        activeColor: Color(red: 0.12, green: 0.84, blue: 0.38),
                        maxHeight: 12
                    )
                } else {
                    // Idle: Show Battery Percentage and Gauge
                    HStack(spacing: 3) {
                        Text("\(battery.batteryPercentage)%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(battery.batteryPercentage < 20 ? .red : .white.opacity(0.85))
                        
                        Image(systemName: battery.isCharging ? "battery.100.bolt" : batteryIconName(for: battery.batteryPercentage))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(battery.isCharging ? .green : (battery.batteryPercentage < 20 ? .red : .white.opacity(0.85)))
                    }
                }
            }
            .frame(width: 48, alignment: .trailing)
            .padding(.trailing, 10)
        }
        .frame(height: notchHeight)
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
        return "battery.25"
    }
}
