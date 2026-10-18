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
        VStack(spacing: 12) {
            // Top Bar: Tab Switcher & Close button
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(ExpandedTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedTab = tab
                            }
                            SoundManager.shared.play(.haptic)
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    selectedTab == tab
                                        ? RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.18))
                                        : RoundedRectangle(cornerRadius: 6).fill(Color.clear)
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
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            .padding(.horizontal, 14)
            
            // Content Body depending on Tab
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
            .padding(.bottom, 12)
        }
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = media.track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        )
                }
                
                // Track & Artist
                VStack(alignment: .leading, spacing: 3) {
                    MarqueeText(
                        text: media.track.title.isEmpty ? "Not Playing" : media.track.title,
                        font: .system(size: 14, weight: .semibold),
                        color: .white
                    )
                    
                    Text(media.track.artist.isEmpty ? "Play media in Music, Spotify or Safari" : media.track.artist)
                        .font(.system(size: 11, weight: .regular))
                        .lineLimit(1)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                WaveformView(
                    isPlaying: media.track.isPlaying,
                    barCount: 5,
                    activeColor: .white,
                    maxHeight: 18
                )
            }
            
            // Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(media.progress))), height: 4)
                    }
                }
                .frame(height: 6)
                
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
            
            // Playback Controls
            HStack(spacing: 28) {
                Button(action: {
                    media.previous()
                    SoundManager.shared.play(.haptic)
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
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
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    media.next()
                    SoundManager.shared.play(.haptic)
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Controls Section (Volume & Brightness)
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Volume Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Volume", systemImage: volume.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(volume.volume * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                Slider(value: Binding(
                    get: { Double(volume.volume) },
                    set: { volume.setVolume(Float($0)) }
                ), in: 0...1)
                .accentColor(.white)
            }
            
            // Brightness Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Display Brightness", systemImage: "sun.max.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(brightness.brightness * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(battery.isCharging ? .green : .white.opacity(0.8))
                Spacer()
                Text("\(battery.batteryPercentage)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(battery.isCharging ? .green : .white)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
        }
    }
    
    // MARK: - AirPods Section
    private var airPodsSection: some View {
        VStack(spacing: 12) {
            if let dev = bluetooth.connectedDevice {
                HStack(spacing: 12) {
                    Image(systemName: "airpodspro")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dev.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Connected")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // Battery indicators: Left, Right, Case
                HStack(spacing: 16) {
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
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No Bluetooth Audio Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, minHeight: 70)
            }
        }
    }
    
    private func batteryPod(label: String, level: Int, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.85))
            Text("\(level)%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(level < 20 ? .red : .white)
            Text(label)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }
}
