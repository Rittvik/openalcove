import Foundation
import AppKit
import Combine

public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public var track: TrackInfo = TrackInfo()
    @Published public var hasActiveMedia: Bool = false
    
    private init() {
        MediaRemoteBridge.shared.onTrackChanged = { [weak self] newTrack in
            DispatchQueue.main.async {
                self?.track = newTrack
                self?.hasActiveMedia = !newTrack.title.isEmpty
            }
        }
        MediaRemoteBridge.shared.updateNowPlaying()
    }
    
    public var progress: Double {
        guard track.duration > 0 else { return 0 }
        return min(1.0, max(0.0, track.elapsedTime / track.duration))
    }
    
    public var formattedElapsed: String {
        formatTime(track.elapsedTime)
    }
    
    public var formattedRemaining: String {
        guard track.duration > track.elapsedTime else { return "0:00" }
        return "-" + formatTime(track.duration - track.elapsedTime)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    public func togglePlayPause() {
        MediaRemoteBridge.shared.togglePlayPause()
    }
    
    public func next() {
        MediaRemoteBridge.shared.nextTrack()
    }
    
    public func previous() {
        MediaRemoteBridge.shared.previousTrack()
    }
}
