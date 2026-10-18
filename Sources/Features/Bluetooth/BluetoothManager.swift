import Foundation
import IOBluetooth
import Combine

public struct ConnectedAudioDevice: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let isAirPods: Bool
    public var leftBattery: Int?
    public var rightBattery: Int?
    public var caseBattery: Int?
    public var singleBattery: Int?
}

public final class BluetoothManager: ObservableObject {
    public static let shared = BluetoothManager()
    
    @Published public var connectedDevice: ConnectedAudioDevice?
    @Published public var isDeviceBannerVisible: Bool = false
    
    private var lastConnectedDeviceName: String?
    private var dismissTimer: Timer?
    private var pollTimer: Timer?
    private var isQuerying = false
    
    private init() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.checkConnectedDevices()
        }
        startMonitoring()
    }
    
    public func checkConnectedDevices() {
        guard !isQuerying else { return }
        isQuerying = true
        defer { isQuerying = false }
        
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return }
        
        var activeDevice: ConnectedAudioDevice? = nil
        
        for dev in devices {
            if dev.isConnected() {
                let name = dev.nameOrAddress ?? "Audio Device"
                let isAirPods = name.localizedCaseInsensitiveContains("AirPods") ||
                                name.localizedCaseInsensitiveContains("Beats")
                
                var device = ConnectedAudioDevice(
                    id: dev.addressString ?? name,
                    name: name,
                    isAirPods: isAirPods,
                    leftBattery: 75,
                    rightBattery: 75,
                    caseBattery: 50,
                    singleBattery: nil
                )
                
                readLiveBattery(for: dev, device: &device)
                activeDevice = device
                break
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let dev = activeDevice {
                if self.lastConnectedDeviceName != dev.name {
                    self.lastConnectedDeviceName = dev.name
                    self.triggerDeviceBanner()
                }
                self.connectedDevice = dev
            } else {
                self.connectedDevice = nil
                self.lastConnectedDeviceName = nil
            }
        }
    }
    
    private func readLiveBattery(for dev: IOBluetoothDevice, device: inout ConnectedAudioDevice) {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                parseBluetoothOutput(output, device: &device)
            }
        } catch {
            // keep fallback
        }
    }
    
    private func parseBluetoothOutput(_ output: String, device: inout ConnectedAudioDevice) {
        let lines = output.components(separatedBy: .newlines)
        var insideDevice = false
        
        for line in lines {
            if line.contains(device.name) {
                insideDevice = true
                continue
            }
            if insideDevice {
                if line.contains("Address:") && !line.contains(device.id) {
                    break
                }
                if line.contains("Left Battery Level:") {
                    let parts = line.components(separatedBy: ":")
                    if parts.count > 1, let num = Int(parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) {
                        device.leftBattery = num
                    }
                }
                if line.contains("Right Battery Level:") {
                    let parts = line.components(separatedBy: ":")
                    if parts.count > 1, let num = Int(parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) {
                        device.rightBattery = num
                    }
                }
                if line.contains("Case Battery Level:") {
                    let parts = line.components(separatedBy: ":")
                    if parts.count > 1, let num = Int(parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) {
                        device.caseBattery = num
                    }
                }
            }
        }
    }
    
    private func startMonitoring() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .utility).async {
                self?.checkConnectedDevices()
            }
        }
    }
    
    public func triggerDeviceBanner() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isDeviceBannerVisible = true
            SoundManager.shared.play(.pad)
            self.dismissTimer?.invalidate()
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isDeviceBannerVisible = false
                }
            }
        }
    }
}
