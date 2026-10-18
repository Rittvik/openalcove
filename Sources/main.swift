import AppKit

final class MainHolder {
    static let delegate = AppDelegate()
}

let app = NSApplication.shared
app.delegate = MainHolder.delegate
app.run()
