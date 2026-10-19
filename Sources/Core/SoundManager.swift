import Foundation
import AVFoundation

public enum SoundEffect: String {
    case volume = "volume"
    case chime = "chime"
    case haptic = "haptic"
    case lock = "lock"
    case unlock = "unlock"
    case lowBattery = "low-battery"
    case sleep = "sleep"
    case pad = "pad"
}

public final class SoundManager: ObservableObject {
    public static let shared = SoundManager()
    
    @Published public var isSoundEnabled: Bool = true
    @Published public var volume: Float = 0.6
    
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {
        preloadSounds()
    }
    
    private func preloadSounds() {
        let soundNames = ["volume", "chime", "haptic", "lock", "unlock", "low-battery", "sleep"]
        for name in soundNames {
            if let url = findSoundURL(name: name) {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    player.volume = volume
                    players[name] = player
                }
            }
        }
    }
    
    private func findSoundURL(name: String) -> URL? {
        // Try Bundle.main
        let extensions = ["caf", "m4a", "mp3", "wav"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds") {
                return url
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
            if let moduleBundle = Bundle.moduleBundle(),
               let url = moduleBundle.url(forResource: name, withExtension: ext) {
                return url
            }
            // Check direct local folder fallback
            let localPath = "/Users/rittvikvashishtha/Notch/Sources/Resources/Sounds/\(name).\(ext)"
            if FileManager.default.fileExists(atPath: localPath) {
                return URL(fileURLWithPath: localPath)
            }
        }
        return nil
    }
    
    public func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            if let player = self.players[effect.rawValue] {
                player.currentTime = 0
                player.volume = self.volume
                player.play()
            } else if let url = self.findSoundURL(name: effect.rawValue) {
                if let newPlayer = try? AVAudioPlayer(contentsOf: url) {
                    newPlayer.volume = self.volume
                    newPlayer.play()
                }
            }
        }
    }
    
    public func playHapticIfEnabled() {
        guard isSoundEnabled && AppSettings.shared.notchHapticsEnabled else { return }
        play(.haptic)
    }
}

extension Bundle {
    static func moduleBundle() -> Bundle? {
        let main = Bundle.main
        if let path = main.path(forResource: "OpenAlcove_OpenAlcove", ofType: "bundle"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return nil
    }
}
