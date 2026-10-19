import SwiftUI

public enum ExpandedTab: String, CaseIterable {
    case media = "Now Playing"
    case controls = "Controls"
    case airpods = "AirPods"
    case shelf = "Drop Shelf"
    
    var icon: String {
        switch self {
        case .media: return "music.note"
        case .controls: return "slider.horizontal.3"
        case .airpods: return "airpodspro"
        case .shelf: return "tray.and.arrow.down.fill"
        }
    }
}

public struct NotchExpandedView: View {
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var volume = VolumeManager.shared
    @ObservedObject var brightness = BrightnessManager.shared
    @ObservedObject var battery = BatteryManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    @ObservedObject var shelf = ShelfManager.shared
    @ObservedObject var geometry = ScreenGeometryManager.shared
    @ObservedObject var settings = AppSettings.shared
    
    @State private var selectedTab: ExpandedTab = .media
    @Namespace private var tabNamespace
    public var onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        let accentColor = Color(nsColor: .controlAccentColor)
        
        VStack(spacing: 8) {
            // Hardware Notch Clearance: Drops entire card down below physical camera housing
            Spacer()
                .frame(height: max(geometry.currentMetrics.physicalHeight, 38) + 6)
            
            // MARK: - Header Bar & Apple Segmented Control
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(ExpandedTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedTab = tab
                            }
                            SoundManager.shared.playHapticIfEnabled()
                        }) {
                            HStack(spacing: 4.5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium, design: .default))
                            }
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.50))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .background {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(settings.useSystemAccentColor ? accentColor.opacity(0.35) : Color.white.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(settings.useSystemAccentColor ? accentColor.opacity(0.50) : Color.white.opacity(0.12), lineWidth: 0.5)
                                        )
                                        .matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)
                                }
                            }
                        }
                        .buttonStyle(ApplePressableButtonStyle(scale: 0.95, pressedOpacity: 0.85))
                    }
                }
                .padding(2.5)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                
                Spacer()
                
                Button(action: {
                    SoundManager.shared.playHapticIfEnabled()
                    onClose()
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                }
                .buttonStyle(ApplePressableButtonStyle(scale: 0.92, pressedOpacity: 0.8))
            }
            .padding(.horizontal, 16)
            
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
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .frame(width: 520, height: 235, alignment: .top)
    }
    
    // MARK: - Media Player
    private var mediaSection: some View {
        let accentColor = Color(nsColor: .controlAccentColor)
        
        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Artwork with continuous squircle corners & inner stroke
                if let artwork = media.track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.12, green: 0.84, blue: 0.38), Color(red: 0.05, green: 0.45, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                
                // Track details
                VStack(alignment: .leading, spacing: 3) {
                    MarqueeText(
                        text: media.track.title.isEmpty ? "No Media Playing" : media.track.title,
                        font: .system(size: 13, weight: .semibold, design: .default),
                        color: .white
                    )
                    
                    Text(media.track.artist.isEmpty ? (media.hasActiveMedia ? "Playing" : "Play music in Spotify, Music or Safari") : media.track.artist)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .lineLimit(1)
                        .foregroundColor(.white.opacity(0.60))
                    
                    if !media.track.album.isEmpty {
                        Text(media.track.album)
                            .font(.system(size: 9.5, weight: .regular, design: .default))
                            .lineLimit(1)
                            .foregroundColor(.white.opacity(0.40))
                    }
                }
                
                Spacer()
                
                WaveformView(
                    isPlaying: media.track.isPlaying,
                    barCount: 5,
                    activeColor: settings.useSystemAccentColor ? accentColor : Color(red: 0.12, green: 0.84, blue: 0.38),
                    maxHeight: 18
                )
            }
            
            // Progress Bar
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 4)
                        Capsule()
                            .fill(settings.useSystemAccentColor ? accentColor : Color.white)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(media.progress))), height: 4)
                    }
                }
                .frame(height: 5)
                
                HStack {
                    Text(media.formattedElapsed)
                        .font(.system(size: 9.5, weight: .medium, design: .default))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text(media.formattedRemaining)
                        .font(.system(size: 9.5, weight: .medium, design: .default))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            
            // Playback Controls with tactile spring feedback
            HStack(spacing: 36) {
                Button(action: {
                    media.previous()
                    SoundManager.shared.playHapticIfEnabled()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(ApplePressableButtonStyle(scale: 0.90, pressedOpacity: 0.75))
                
                Button(action: {
                    media.togglePlayPause()
                    SoundManager.shared.playHapticIfEnabled()
                }) {
                    Image(systemName: media.track.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                        .shadow(color: settings.useSystemAccentColor ? accentColor.opacity(0.4) : .white.opacity(0.18), radius: 6)
                }
                .buttonStyle(ApplePressableButtonStyle(scale: 0.92, pressedOpacity: 0.85))
                
                Button(action: {
                    media.next()
                    SoundManager.shared.playHapticIfEnabled()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(ApplePressableButtonStyle(scale: 0.90, pressedOpacity: 0.75))
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Controls
    private var controlsSection: some View {
        let accentColor = Color(nsColor: .controlAccentColor)
        
        return VStack(spacing: 7) {
            // macOS Control Center Capsule Volume Slider
            AppleControlSlider(
                value: Binding(
                    get: { Double(volume.volume) },
                    set: { volume.setVolume(Float($0)) }
                ),
                iconName: volume.isMuted ? "speaker.slash.fill" : (volume.volume > 0.6 ? "speaker.wave.3.fill" : (volume.volume > 0.2 ? "speaker.wave.2.fill" : "speaker.wave.1.fill")),
                label: "Volume",
                tintColor: settings.useSystemAccentColor ? accentColor : .white
            )
            
            // macOS Control Center Capsule Display Brightness Slider
            AppleControlSlider(
                value: Binding(
                    get: { Double(brightness.brightness) },
                    set: { brightness.setBrightness(Float($0)) }
                ),
                iconName: "sun.max.fill",
                label: "Display Brightness",
                tintColor: settings.useSystemAccentColor ? accentColor : .yellow
            )
            
            // Quick Action Card Tiles: Accent Color, Stealth Mode & Haptic Pop Sound Toggle
            HStack(spacing: 6) {
                AppleActionTile(
                    iconName: "paintpalette.fill",
                    title: "Accent",
                    subtitle: settings.useSystemAccentColor ? "System" : "Mono",
                    isActive: settings.useSystemAccentColor,
                    activeColor: accentColor
                ) {
                    settings.useSystemAccentColor.toggle()
                    SoundManager.shared.playHapticIfEnabled()
                }
                
                AppleActionTile(
                    iconName: "eye.slash.fill",
                    title: "Stealth",
                    subtitle: settings.hideWingsBehindNotch ? "Hidden" : "Visible",
                    isActive: settings.hideWingsBehindNotch,
                    activeColor: .green
                ) {
                    settings.hideWingsBehindNotch.toggle()
                    SoundManager.shared.playHapticIfEnabled()
                }
                
                // USER REQUEST: Dedicated toggle to turn off haptic pop sound when notch is active
                AppleActionTile(
                    iconName: settings.notchHapticsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    title: "Haptic Pop",
                    subtitle: settings.notchHapticsEnabled ? "Active" : "Muted",
                    isActive: settings.notchHapticsEnabled,
                    activeColor: settings.useSystemAccentColor ? accentColor : Color(red: 0.12, green: 0.84, blue: 0.38)
                ) {
                    settings.notchHapticsEnabled.toggle()
                    if settings.notchHapticsEnabled {
                        SoundManager.shared.play(.haptic)
                    }
                }
            }
            
            // Battery Status Bar
            HStack(spacing: 8) {
                Image(systemName: battery.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(battery.isCharging ? .green : .white.opacity(0.8))
                
                Text(battery.timeRemainingString)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(battery.batteryPercentage)%")
                    .font(.system(size: 10.5, weight: .bold, design: .default))
                    .monospacedDigit()
                    .foregroundColor(battery.isCharging ? .green : .white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
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
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("Connected & Active")
                                .font(.system(size: 9.5, weight: .medium, design: .default))
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                }
                
                HStack(spacing: 10) {
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
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.50))
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
    }
    
    private func batteryPod(label: String, level: Int, icon: String) -> some View {
        VStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.85))
            
            Text("\(level)%")
                .font(.system(size: 11, weight: .bold, design: .default))
                .monospacedDigit()
                .foregroundColor(level < 20 ? .red : .white)
            
            Text(label)
                .font(.system(size: 9, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
