import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var sound = SoundManager.shared
    
    public init() {}
    
    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            featuresTab
                .tabItem {
                    Label("Features", systemImage: "sparkles")
                }
            
            soundTab
                .tabItem {
                    Label("Sound & Haptics", systemImage: "speaker.wave.2")
                }
            
            aboutTab
                .tabItem {
                    Label("Freedom", systemImage: "lock.open.fill")
                }
        }
        .frame(width: 460, height: 320)
        .padding()
    }
    
    private var generalTab: some View {
        Form {
            Section("Display & Layout") {
                Toggle("Enable Notch Island", isOn: $settings.isNotchEnabled)
                Toggle("Compact Wings (show mini waveform & artwork)", isOn: $settings.compactMode)
                Toggle("Simulate Notch on External Displays", isOn: $settings.virtualNotchOnExternalDisplays)
            }
            
            Section("Appearance & Styling") {
                Toggle("Follow macOS System Accent Color", isOn: $settings.useSystemAccentColor)
            }
        }
        .padding(16)
    }
    
    private var featuresTab: some View {
        Form {
            Section("Notch HUD Replacements") {
                Toggle("Fluid Volume HUD", isOn: $settings.volumeHUDEnabled)
                Toggle("Display Brightness HUD", isOn: $settings.brightnessHUDEnabled)
                Toggle("MagSafe & Battery Charging Alerts", isOn: $settings.batteryHUDEnabled)
                Toggle("AirPods & Bluetooth Connection Banner", isOn: $settings.airPodsHUDEnabled)
                Toggle("Alcove Drag & Drop Shelf", isOn: $settings.shelfEnabled)
            }
        }
        .padding(16)
    }
    
    private var soundTab: some View {
        Form {
            Section {
                Toggle("Enable Sound Effects", isOn: $settings.soundEffectsEnabled)
                
                if settings.soundEffectsEnabled {
                    Slider(value: Binding(
                        get: { Double(sound.volume) },
                        set: { sound.volume = Float($0) }
                    ), in: 0...1) {
                        Text("Effect Volume")
                    }
                    
                    HStack {
                        Button("Test Volume Tick") { sound.play(.volume) }
                        Button("Test Charging Chime") { sound.play(.chime) }
                        Button("Test Haptic Pop") { sound.play(.haptic) }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
    }
    
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("OpenAlcove for MacBook Pro")
                .font(.system(size: 16, weight: .bold))
            
            Text("Re-engineered with REA (Reverse-Engineering-Anything)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text("✅ 100% Free Forever")
                Text("✅ Zero Paywalls or Subscriptions")
                Text("✅ All Pro Features Unlocked")
                Text("✅ 100% Local & Privacy First")
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
            
            Text("Version 1.7.7 • Open Source")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
