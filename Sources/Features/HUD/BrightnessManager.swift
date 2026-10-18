import Foundation
import CoreGraphics
import Combine

public final class BrightnessManager: ObservableObject {
    public static let shared = BrightnessManager()
    
    @Published public var brightness: Float = 0.5
    @Published public var isHUDVisible: Bool = false
    
    private typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    
    private var getBrightnessFunc: DisplayServicesGetBrightnessFunc?
    private var setBrightnessFunc: DisplayServicesSetBrightnessFunc?
    private var dismissTimer: Timer?
    private var lastObservedBrightness: Float = 0.5
    private var pollTimer: Timer?
    
    private init() {
        loadFramework()
        readCurrentBrightness()
        startPolling()
    }
    
    private func loadFramework() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW) else {
            return
        }
        if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
            getBrightnessFunc = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessFunc.self)
        }
        if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
            setBrightnessFunc = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
        }
    }
    
    public func readCurrentBrightness() {
        guard let getFunc = getBrightnessFunc else { return }
        var b: Float = 0.0
        let res = getFunc(CGMainDisplayID(), &b)
        if res == 0 {
            self.brightness = b
            self.lastObservedBrightness = b
        }
    }
    
    private func startPolling() {
        // Poll at 200ms interval to catch brightness key changes smoothly
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, let getFunc = self.getBrightnessFunc else { return }
            var b: Float = 0.0
            if getFunc(CGMainDisplayID(), &b) == 0 {
                if abs(b - self.lastObservedBrightness) > 0.01 {
                    self.lastObservedBrightness = b
                    self.brightness = b
                    self.triggerHUD()
                }
            }
        }
    }
    
    public func triggerHUD() {
        isHUDVisible = true
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isHUDVisible = false
            }
        }
    }
    
    public func setBrightness(_ newBrightness: Float) {
        guard let setFunc = setBrightnessFunc else { return }
        let val = max(0.0, min(1.0, newBrightness))
        self.brightness = val
        self.lastObservedBrightness = val
        _ = setFunc(CGMainDisplayID(), val)
    }
}
