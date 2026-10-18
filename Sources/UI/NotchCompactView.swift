import SwiftUI

public struct NotchCompactView: View {
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    
    public init(notchWidth: CGFloat, notchHeight: CGFloat) {
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Left Wing
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
                } else if media.hasActiveMedia {
                    if let artwork = media.track.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pink)
                    }
                }
            }
            .frame(width: 28, alignment: .center)
            
            // Physical Notch Spacing Gap
            Spacer()
                .frame(width: max(0, notchWidth - 68))
            
            // Right Wing
            HStack(spacing: 6) {
                if volume.isHUDVisible {
                    // Mini volume bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                            Capsule().fill(Color.white)
                                .frame(width: geo.size.width * CGFloat(volume.volume))
                        }
                    }
                    .frame(width: 38, height: 4)
                } else if brightness.isHUDVisible {
                    // Mini brightness bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                            Capsule().fill(Color.yellow)
                                .frame(width: geo.size.width * CGFloat(brightness.brightness))
                        }
                    }
                    .frame(width: 38, height: 4)
                } else if battery.isChargingHUDVisible {
                    Text("\(battery.batteryPercentage)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                } else if bluetooth.isDeviceBannerVisible {
                    Text("Connected")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                } else if media.hasActiveMedia {
                    WaveformView(
                        isPlaying: media.track.isPlaying,
                        barCount: 4,
                        activeColor: .green,
                        maxHeight: 12
                    )
                }
            }
            .frame(width: 38, alignment: .center)
        }
        .frame(height: notchHeight)
        .padding(.horizontal, 10)
    }
}
