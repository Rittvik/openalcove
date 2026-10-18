import Foundation
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    @Published public var isNotchEnabled: Bool {
        didSet { defaults.set(isNotchEnabled, forKey: "isNotchEnabled") }
    }
    @Published public var compactMode: Bool {
        didSet { defaults.set(compactMode, forKey: "compactMode") }
    }
    @Published public var volumeHUDEnabled: Bool {
        didSet { defaults.set(volumeHUDEnabled, forKey: "volumeHUDEnabled") }
    }
    @Published public var brightnessHUDEnabled: Bool {
        didSet { defaults.set(brightnessHUDEnabled, forKey: "brightnessHUDEnabled") }
    }
    @Published public var batteryHUDEnabled: Bool {
        didSet { defaults.set(batteryHUDEnabled, forKey: "batteryHUDEnabled") }
    }
    @Published public var airPodsHUDEnabled: Bool {
        didSet { defaults.set(airPodsHUDEnabled, forKey: "airPodsHUDEnabled") }
    }
    @Published public var soundEffectsEnabled: Bool {
        didSet {
            defaults.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
            SoundManager.shared.isSoundEnabled = soundEffectsEnabled
        }
    }
    @Published public var shelfEnabled: Bool {
        didSet { defaults.set(shelfEnabled, forKey: "shelfEnabled") }
    }
    @Published public var virtualNotchOnExternalDisplays: Bool {
        didSet { defaults.set(virtualNotchOnExternalDisplays, forKey: "virtualNotchOnExternalDisplays") }
    }
    @Published public var useSystemAccentColor: Bool {
        didSet { defaults.set(useSystemAccentColor, forKey: "useSystemAccentColor") }
    }
    @Published public var hideWingsBehindNotch: Bool {
        didSet {
            defaults.set(hideWingsBehindNotch, forKey: "hideWingsBehindNotch")
            DispatchQueue.main.async {
                NotchController.shared.reposition()
            }
        }
    }
    
    public let isFreeAndUnlimitedForever: Bool = true
    
    private init() {
        self.isNotchEnabled = defaults.object(forKey: "isNotchEnabled") as? Bool ?? true
        self.compactMode = defaults.object(forKey: "compactMode") as? Bool ?? true
        self.volumeHUDEnabled = defaults.object(forKey: "volumeHUDEnabled") as? Bool ?? true
        self.brightnessHUDEnabled = defaults.object(forKey: "brightnessHUDEnabled") as? Bool ?? true
        self.batteryHUDEnabled = defaults.object(forKey: "batteryHUDEnabled") as? Bool ?? true
        self.airPodsHUDEnabled = defaults.object(forKey: "airPodsHUDEnabled") as? Bool ?? true
        self.soundEffectsEnabled = defaults.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        self.shelfEnabled = defaults.object(forKey: "shelfEnabled") as? Bool ?? true
        self.virtualNotchOnExternalDisplays = defaults.object(forKey: "virtualNotchOnExternalDisplays") as? Bool ?? false
        self.useSystemAccentColor = defaults.object(forKey: "useSystemAccentColor") as? Bool ?? true
        self.hideWingsBehindNotch = defaults.object(forKey: "hideWingsBehindNotch") as? Bool ?? false
        
        SoundManager.shared.isSoundEnabled = self.soundEffectsEnabled
    }
}
