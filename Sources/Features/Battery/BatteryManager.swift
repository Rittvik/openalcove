import Foundation
import IOKit.ps
import Combine

public final class BatteryManager: ObservableObject {
    public static let shared = BatteryManager()
    
    @Published public var batteryPercentage: Int = 100
    @Published public var isCharging: Bool = false
    @Published public var isPluggedIn: Bool = false
    @Published public var timeRemainingString: String = ""
    @Published public var isChargingHUDVisible: Bool = false
    
    private var lastChargingState: Bool = false
    private var dismissTimer: Timer?
    private var pollTimer: Timer?
    
    private init() {
        updateBatteryState()
        lastChargingState = isCharging
        startMonitoring()
    }
    
    public func updateBatteryState() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return }
        guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else { return }
        
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            
            if let cap = desc[kIOPSCurrentCapacityKey] as? Int {
                self.batteryPercentage = cap
            }
            if let charging = desc[kIOPSIsChargingKey] as? Bool {
                let wasCharging = self.lastChargingState
                self.isCharging = charging
                if charging && !wasCharging {
                    triggerChargingHUD()
                }
                self.lastChargingState = charging
            }
            if let state = desc[kIOPSPowerSourceStateKey] as? String {
                self.isPluggedIn = (state == kIOPSACPowerValue)
            }
            if let timeRemaining = desc[kIOPSTimeToEmptyKey] as? Int, timeRemaining > 0 {
                let hours = timeRemaining / 60
                let mins = timeRemaining % 60
                self.timeRemainingString = "\(hours)h \(mins)m remaining"
            } else if let timeToFull = desc[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                let hours = timeToFull / 60
                let mins = timeToFull % 60
                self.timeRemainingString = "\(hours)h \(mins)m until full"
            } else {
                self.timeRemainingString = isCharging ? "Charging" : "On Battery"
            }
        }
    }
    
    private func startMonitoring() {
        // Poll every 3 seconds
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateBatteryState()
            }
        }
    }
    
    public func triggerChargingHUD() {
        isChargingHUDVisible = true
        SoundManager.shared.play(.chime)
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isChargingHUDVisible = false
            }
        }
    }
}
