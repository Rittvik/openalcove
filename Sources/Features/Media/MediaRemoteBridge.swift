import Foundation
import AppKit

public struct TrackInfo: Equatable {
    public var title: String
    public var artist: String
    public var album: String
    public var artwork: NSImage?
    public var duration: Double
    public var elapsedTime: Double
    public var isPlaying: Bool
    public var source: String // "spotify", "music", "mediaremote"
    
    public init(
        title: String = "",
        artist: String = "",
        album: String = "",
        artwork: NSImage? = nil,
        duration: Double = 0,
        elapsedTime: Double = 0,
        isPlaying: Bool = false,
        source: String = ""
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.artwork = artwork
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.isPlaying = isPlaying
        self.source = source
    }
}

public final class MediaRemoteBridge {
    public static let shared = MediaRemoteBridge()
    
    private typealias MRRegisterFunc = @convention(c) (DispatchQueue) -> Void
    private typealias MRGetInfoFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRIsPlayingFunc = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRSendCommandFunc = @convention(c) (Int32, AnyObject?) -> Bool
    
    private var registerForNotifications: MRRegisterFunc?
    private var getNowPlayingInfo: MRGetInfoFunc?
    private var getIsPlaying: MRIsPlayingFunc?
    private var sendCommand: MRSendCommandFunc?
    
    public var onTrackChanged: ((TrackInfo) -> Void)?
    
    public var currentTrack = TrackInfo()
    private var pollTimer: Timer?
    private var lastArtworkURL: String?
    
    private init() {
        loadFramework()
        startObserving()
    }
    
    private func loadFramework() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            return
        }
        
        if let regSym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerForNotifications = unsafeBitCast(regSym, to: MRRegisterFunc.self)
        }
        if let infoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfo = unsafeBitCast(infoSym, to: MRGetInfoFunc.self)
        }
        if let playSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlaying = unsafeBitCast(playSym, to: MRIsPlayingFunc.self)
        }
        if let cmdSym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(cmdSym, to: MRSendCommandFunc.self)
        }
    }
    
    private func startObserving() {
        registerForNotifications?(DispatchQueue.main)
        
        // Initial fetch
        updateNowPlaying()
        
        // Active polling every 1 second: keeps Now Playing accurate across all apps
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }
    
    public func updateNowPlaying() {
        // Priority 1: Check Spotify directly if active
        if checkSpotify() {
            return
        }
        
        // Priority 2: Check Apple Music directly if active
        if checkAppleMusic() {
            return
        }
        
        // Priority 3: MediaRemote framework (YouTube in Safari/Chrome, Podcasts, Web browsers)
        checkMediaRemote()
    }
    
    private func checkSpotify() -> Bool {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    set artUrl to artwork url of current track
                    set playerState to player state as string
                    set playerPos to player position as integer
                    set trackDur to duration of current track as integer
                    return trackName & "|||" & artistName & "|||" & albumName & "|||" & artUrl & "|||" & playerState & "|||" & (playerPos as string) & "|||" & (trackDur as string)
                on error
                    return ""
                end try
            end tell
        else
            return ""
        end if
        """
        
        guard let output = runAppleScript(script), !output.isEmpty, output.contains("|||") else {
            return false
        }
        
        let parts = output.components(separatedBy: "|||")
        if parts.count >= 5 {
            let title = parts[0]
            let artist = parts[1]
            let album = parts[2]
            let artUrl = parts[3]
            let state = parts[4].lowercased()
            let isPlaying = (state == "playing")
            
            var elapsed: Double = 0
            var duration: Double = 0
            if parts.count >= 7 {
                elapsed = Double(parts[5]) ?? 0
                duration = (Double(parts[6]) ?? 0) / 1000.0 // Spotify duration is in ms
            }
            
            self.currentTrack.title = title
            self.currentTrack.artist = artist
            self.currentTrack.album = album
            self.currentTrack.isPlaying = isPlaying
            self.currentTrack.elapsedTime = elapsed
            self.currentTrack.duration = duration
            self.currentTrack.source = "spotify"
            
            // Fetch artwork asynchronously if changed
            if !artUrl.isEmpty && artUrl != self.lastArtworkURL {
                self.lastArtworkURL = artUrl
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    if let url = URL(string: artUrl), let data = try? Data(contentsOf: url), let img = NSImage(data: data) {
                        DispatchQueue.main.async {
                            self?.currentTrack.artwork = img
                            self?.notifyChange()
                        }
                    }
                }
            }
            
            notifyChange()
            return true
        }
        return false
    }
    
    private func checkAppleMusic() -> Bool {
        let script = """
        if application "Music" is running then
            tell application "Music"
                try
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set playerState to player state as string
                        set playerPos to player position as integer
                        set trackDur to duration of current track as integer
                        return trackName & "|||" & artistName & "|||" & albumName & "|||" & playerState & "|||" & (playerPos as string) & "|||" & (trackDur as string)
                    end if
                on error
                    return ""
                end try
            end tell
        end if
        return ""
        """
        
        guard let output = runAppleScript(script), !output.isEmpty, output.contains("|||") else {
            return false
        }
        
        let parts = output.components(separatedBy: "|||")
        if parts.count >= 4 {
            let title = parts[0]
            let artist = parts[1]
            let album = parts[2]
            let state = parts[3].lowercased()
            let isPlaying = (state == "playing")
            
            var elapsed: Double = 0
            var duration: Double = 0
            if parts.count >= 6 {
                elapsed = Double(parts[4]) ?? 0
                duration = Double(parts[5]) ?? 0
            }
            
            self.currentTrack.title = title
            self.currentTrack.artist = artist
            self.currentTrack.album = album
            self.currentTrack.isPlaying = isPlaying
            self.currentTrack.elapsedTime = elapsed
            self.currentTrack.duration = duration
            self.currentTrack.source = "music"
            
            notifyChange()
            return true
        }
        return false
    }
    
    private func checkMediaRemote() {
        guard let getInfo = getNowPlayingInfo else { return }
        
        getInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
            let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0.0
            let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0.0
            let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0.0
            
            if !title.isEmpty {
                self.currentTrack.title = title
                self.currentTrack.artist = artist
                self.currentTrack.album = album
                self.currentTrack.duration = duration
                self.currentTrack.elapsedTime = elapsed
                self.currentTrack.isPlaying = (rate > 0.0)
                self.currentTrack.source = "mediaremote"
                
                if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    self.currentTrack.artwork = NSImage(data: data)
                }
                
                self.notifyChange()
            } else if self.currentTrack.source == "mediaremote" {
                // Cleared
                self.currentTrack = TrackInfo()
                self.notifyChange()
            }
        }
    }
    
    private func notifyChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onTrackChanged?(self.currentTrack)
        }
    }
    
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }
    
    public func togglePlayPause() {
        if currentTrack.source == "spotify" {
            _ = runAppleScript("tell application \"Spotify\" to playpause")
        } else if currentTrack.source == "music" {
            _ = runAppleScript("tell application \"Music\" to playpause")
        } else {
            _ = sendCommand?(2, nil) // 2 = kMRTogglePlayPause
        }
        currentTrack.isPlaying.toggle()
        notifyChange()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateNowPlaying()
        }
    }
    
    public func nextTrack() {
        if currentTrack.source == "spotify" {
            _ = runAppleScript("tell application \"Spotify\" to next track")
        } else if currentTrack.source == "music" {
            _ = runAppleScript("tell application \"Music\" to next track")
        } else {
            _ = sendCommand?(4, nil) // 4 = kMRNextTrack
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateNowPlaying()
        }
    }
    
    public func previousTrack() {
        if currentTrack.source == "spotify" {
            _ = runAppleScript("tell application \"Spotify\" to previous track")
        } else if currentTrack.source == "music" {
            _ = runAppleScript("tell application \"Music\" to previous track")
        } else {
            _ = sendCommand?(5, nil) // 5 = kMRPreviousTrack
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateNowPlaying()
        }
    }
}
