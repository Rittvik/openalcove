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
    public var bundleIdentifier: String?
    
    public init(
        title: String = "",
        artist: String = "",
        album: String = "",
        artwork: NSImage? = nil,
        duration: Double = 0,
        elapsedTime: Double = 0,
        isPlaying: Bool = false,
        bundleIdentifier: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.artwork = artwork
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.isPlaying = isPlaying
        self.bundleIdentifier = bundleIdentifier
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
    
    private var currentTrack = TrackInfo()
    private var pollTimer: Timer?
    
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
        
        let nc = NotificationCenter.default
        let notificationNames = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"
        ]
        
        for name in notificationNames {
            nc.addObserver(
                self,
                selector: #selector(handleNotification),
                name: NSNotification.Name(name),
                object: nil
            )
        }
        
        // Also observe distributed notifications for Spotify and Apple Music
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            self,
            selector: #selector(handleNotification),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
        dnc.addObserver(
            self,
            selector: #selector(handleNotification),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        
        // Initial query
        updateNowPlaying()
        
        // Timer for progress updates when playing
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.currentTrack.isPlaying {
                self.currentTrack.elapsedTime = min(self.currentTrack.duration, self.currentTrack.elapsedTime + 1.0)
                self.onTrackChanged?(self.currentTrack)
            }
        }
    }
    
    @objc private func handleNotification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateNowPlaying()
        }
    }
    
    public func updateNowPlaying() {
        getIsPlaying?(DispatchQueue.main) { [weak self] playing in
            guard let self = self else { return }
            self.currentTrack.isPlaying = playing
            
            self.getNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
                guard let self = self else { return }
                
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0.0
                let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0.0
                
                var artwork: NSImage? = nil
                if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    artwork = NSImage(data: data)
                }
                
                self.currentTrack.title = title
                self.currentTrack.artist = artist
                self.currentTrack.album = album
                self.currentTrack.duration = duration
                self.currentTrack.elapsedTime = elapsed
                if artwork != nil {
                    self.currentTrack.artwork = artwork
                }
                
                DispatchQueue.main.async {
                    self.onTrackChanged?(self.currentTrack)
                }
            }
        }
    }
    
    public func togglePlayPause() {
        _ = sendCommand?(2, nil) // 2 = kMRTogglePlayPause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateNowPlaying()
        }
    }
    
    public func nextTrack() {
        _ = sendCommand?(4, nil) // 4 = kMRNextTrack
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateNowPlaying()
        }
    }
    
    public func previousTrack() {
        _ = sendCommand?(5, nil) // 5 = kMRPreviousTrack
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateNowPlaying()
        }
    }
}
