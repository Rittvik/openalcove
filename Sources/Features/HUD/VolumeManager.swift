import Foundation
import CoreAudio
import Combine

public final class VolumeManager: ObservableObject {
    public static let shared = VolumeManager()
    
    @Published public var volume: Float = 0.5
    @Published public var isMuted: Bool = false
    @Published public var isHUDVisible: Bool = false
    
    private var defaultOutputDeviceID = AudioObjectID(0)
    private var dismissTimer: Timer?
    private var isProgrammaticChange = false
    
    private init() {
        setupCoreAudio()
    }
    
    private func setupCoreAudio() {
        updateDefaultDevice()
        readCurrentVolume()
        registerListener()
        registerDeviceChangeListener()
    }
    
    private func updateDefaultDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &size,
            &defaultOutputDeviceID
        )
    }
    
    private func readCurrentVolume() {
        guard defaultOutputDeviceID != 0 else { return }
        
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var vol: Float32 = 0.0
            var volumeAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            var volSize = UInt32(MemoryLayout<Float32>.size)
            let status = AudioObjectGetPropertyData(
                defaultOutputDeviceID,
                &volumeAddress,
                0,
                nil,
                &volSize,
                &vol
            )
            if status == noErr {
                self.volume = vol
                break
            }
        }
        
        // Check mute
        var mute: UInt32 = 0
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        let muteStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &muteAddress,
            0,
            nil,
            &muteSize,
            &mute
        )
        if muteStatus == noErr {
            self.isMuted = (mute != 0)
        }
    }
    
    private func registerListener() {
        guard defaultOutputDeviceID != 0 else { return }
        
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var volumeAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            
            let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if self.isProgrammaticChange {
                        self.isProgrammaticChange = false
                        return
                    }
                    self.readCurrentVolume()
                    self.triggerHUD()
                }
            }
            
            _ = AudioObjectAddPropertyListenerBlock(
                defaultOutputDeviceID,
                &volumeAddress,
                DispatchQueue.main,
                block
            )
        }
    }
    
    private func registerDeviceChangeListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateDefaultDevice()
                self?.readCurrentVolume()
                self?.registerListener()
            }
        }
        _ = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )
    }
    
    public func triggerHUD() {
        isHUDVisible = true
        SoundManager.shared.play(.volume)
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isHUDVisible = false
            }
        }
    }
    
    public func setVolume(_ newVol: Float) {
        guard defaultOutputDeviceID != 0 else { return }
        isProgrammaticChange = true
        var vol = max(0.0, min(1.0, newVol))
        self.volume = vol
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var volumeAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            let volSize = UInt32(MemoryLayout<Float32>.size)
            _ = AudioObjectSetPropertyData(
                defaultOutputDeviceID,
                &volumeAddress,
                0,
                nil,
                volSize,
                &vol
            )
        }
    }
}
