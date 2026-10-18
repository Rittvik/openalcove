import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent AppKit from automatically terminating this background agent
        ProcessInfo.processInfo.disableAutomaticTermination("OpenAlcove daemon")
        
        // Hide dock icon (LSUIElement behavior)
        NSApp.setActivationPolicy(.accessory)
        
        // Start Notch Island
        NotchController.shared.start()
        
        // Setup Menu Bar Status Item
        setupStatusBar()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "macbook.gen2", accessibilityDescription: "OpenAlcove")
        
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "OpenAlcove (All Features Free)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: "Toggle Notch Island", action: #selector(toggleNotch), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let playItem = NSMenuItem(title: "Play / Pause", action: #selector(togglePlayback), keyEquivalent: " ")
        playItem.target = self
        menu.addItem(playItem)
        
        let nextItem = NSMenuItem(title: "Next Track", action: #selector(nextTrack), keyEquivalent: "]")
        nextItem.target = self
        menu.addItem(nextItem)
        
        let prevItem = NSMenuItem(title: "Previous Track", action: #selector(prevTrack), keyEquivalent: "[")
        prevItem.target = self
        menu.addItem(prevItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit OpenAlcove", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleNotch() {
        AppSettings.shared.isNotchEnabled.toggle()
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "OpenAlcove Settings"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func togglePlayback() {
        MediaManager.shared.togglePlayPause()
    }
    
    @objc private func nextTrack() {
        MediaManager.shared.next()
    }
    
    @objc private func prevTrack() {
        MediaManager.shared.previous()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
