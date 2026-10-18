import SwiftUI

public enum ExpandedTab: String, CaseIterable {
    case media = "Now Playing"
    case controls = "Controls"
    case airpods = "AirPods"
    case shelf = "Drop Shelf"
}

public struct NotchExpandedView: View {
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    @ObservedObject var shelf = ShelfManager.shared
    
    @State private var selectedTab: ExpandedTab = .media
    public var onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // MARK: - Header Bar & Tab Switcher
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(ExpandedTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                selectedTab = tab
                            }
                            SoundManager.shared.play(.haptic)
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.45))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    selectedTab == tab
                                        ? RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.16))
                                        : RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    SoundManager.shared.play(.haptic)
                    onClose()
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(5)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
            .padding(.horizontal, 14)
            
            // MARK: - Tab Body
            Group {
                switch selectedTab {
                case .media:
                    mediaSection
                case .controls:
                    controlsSection
                case .airpods:
                    airPodsSection
                case .shelf:
                    ShelfDropzoneView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .frame(width: 390, height: 200)
    }
    
    // MARK: - Media Player
    private var mediaSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = media.track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.12, green: 0.84, blue: 0.38), Color(red: 0.05, green: 0.45, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // Track details
                VStack(alignment: .leading, spacing: 3) {
                    MarqueeText(
                        text: media.track.title.isEmpty ? "No Media Playing" : media.track.title,
                        font: .system(size: 13, weight: .bold, design: .rounded),
                        color: .white
                    )
                    
                    Text(media.track.artist.isEmpty ? (media.hasActiveMedia ? "Playing" : "Play music in Spotify, Music or Safari") : media.track.artist)
                        .font(.system(size: 11, weight: .regular))
                        .lineLimit(1)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if !media.track.album.isEmpty {
                        Text(media.track.album)
                            .font(.system(size: 9, weight: .regular))
                            .lineLimit(1)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                WaveformView(
                    isPlaying: media.track.isPlaying,
                    barCount: 5,
                    activeColor: Color(red: 0.12, green: 0.84, blue: 0.38),
                    maxHeight: 18
                )
            }
            
            // Progress Bar
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 3.5)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(media.progress))), height: 3.5)
                    }
                }
                .frame(height: 5)
                
                HStack {
                    Text(media.formattedElapsed)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text(media.formattedRemaining)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            // Controls
            HStack(spacing: 32) {
                Button(action: {
                    media.previous()
                    SoundManager.shared.play(.haptic)
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    media.togglePlayPause()
                    SoundManager.shared.play(.haptic)
                }) {
                    Image(systemName: media.track.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.15), radius: 6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    media.next()
                    SoundManager.shared.play(.haptic)
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 1)
        }
    }
    
    // MARK: - Controls
    private var controlsSection: some View {
        VStack(spacing: 10) {
            // Volume
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Label("Volume", systemImage: volume.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(volume.volume * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                Slider(value: Binding(
                    get: { Double(volume.volume) },
                    set: { volume.setVolume(Float($0)) }
                ), in: 0...1)
                .accentColor(.white)
            }
            
            // Brightness
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Label("Display Brightness", systemImage: "sun.max.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(brightness.brightness * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                Slider(value: Binding(
                    get: { Double(brightness.brightness) },
                    set: { brightness.setBrightness(Float($0)) }
                ), in: 0...1)
                .accentColor(.yellow)
            }
            
            // Battery Status
            HStack {
                Label(battery.timeRemainingString, systemImage: battery.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(battery.isCharging ? .green : .white.opacity(0.8))
                Spacer()
                Text("\(battery.batteryPercentage)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(battery.isCharging ? .green : .white)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
        }
    }
    
    // MARK: - AirPods
    private var airPodsSection: some View {
        VStack(spacing: 10) {
            if let dev = bluetooth.connectedDevice {
                HStack(spacing: 10) {
                    Image(systemName: "airpodspro")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(dev.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Connected & Active")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    if let left = dev.leftBattery {
                        batteryPod(label: "Left", level: left, icon: "airpod.left")
                    }
                    if let right = dev.rightBattery {
                        batteryPod(label: "Right", level: right, icon: "airpod.right")
                    }
                    if let caseBat = dev.caseBattery {
                        batteryPod(label: "Case", level: caseBat, icon: "airpodspro.chargingcase")
                    }
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.35))
                    Text("No Bluetooth Audio Connected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
    }
    
    private func batteryPod(label: String, level: Int, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.85))
            Text("\(level)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(level < 20 ? .red : .white)
            Text(label)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
    }
}
