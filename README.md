# OpenAlcove 🏔️

**OpenAlcove** is an open-source, 100% free re-engineering of the **Alcove** MacBook Pro notch application, reverse-engineered using the **REA (Reverse-Engineer-Anything)** framework with Hopper Disassembler and native macOS system frameworks.

All features that previously required a paid license or expired after a trial are **unlocked forever** and run completely on-device with zero telemetry, zero paywalls, and zero cloud dependency.

---

## ⚡ Key Features Rebuilt

1. **Dynamic Island Notch Panel**:
   - **Hardware Notch Detection**: Automatically reads `NSScreen.safeAreaInsets.top` and `screen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea` to match your display notch down to the exact pixel.
   - **Virtual Notch Support**: Simulates a sleek dynamic island on non-notch Macs or external monitors.
   - **Window Behavior (Decompiled with REA)**:
     - Window Level: `CGShieldingWindowLevel() + 1` (floats smoothly above menus and full-screen apps).
     - Collection Behavior: `[.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]` (collection flag `0x151`).
     - Non-activating panel (`canBecomeKey = false`, `canBecomeMain = false`) ensuring it never steals keyboard focus from active apps.

2. **Now Playing Media Island**:
   - Real-time media playback integration with Apple Music, Spotify, YouTube, Safari, Chrome, and Podcasts via `MediaRemote.framework`.
   - **Live Artwork**: Album art extraction with rounded continuous corners.
   - **Marquee Text**: Automatically scrolls long track titles and artist names smoothly.
   - **Waveform Visualizer**: Multi-bar animated audio waveform that pulses while audio is actively playing.
   - **Interactive Playback Controls**: Previous, Play/Pause, and Next track controls.
   - **Scrubbable Progress Bar**: Live elapsed time, remaining time, and progress visualization.

3. **System HUD Replacements**:
   - **Fluid Volume HUD**: Intercepts CoreAudio volume events (`AudioObjectAddPropertyListenerBlock`), blooms from the notch with speaker icon and volume fill bar, and plays subtle volume tick feedback.
   - **Display Brightness HUD**: Monitors screen brightness (`DisplayServices.framework`) with sun icon and animated level.
   - **Charging & MagSafe Alert**: Triggers a green charging animation with battery percentage and Apple charging chime whenever USB-C or MagSafe is plugged in.

4. **AirPods & Bluetooth Audio Integration**:
   - Monitors connected devices via `IOBluetooth`.
   - Detects AirPods Pro, AirPods Max, and standard AirPods.
   - Real-time battery status gauges for **Left Earbud**, **Right Earbud**, and **Charging Case**.

5. **Alcove File Shelf (Dropzone)**:
   - Drag files directly onto the notch to park them while switching spaces or full-screen apps.
   - Drag files out to your target destination with full drag-and-drop support.

6. **Audio Feedback & Haptics**:
   - Native Apple-style sound effects for volume adjustments, snap/expand haptics, charging chimes, and lock/unlock cues.

7. **Menu Bar Status Item & Settings**:
   - Native status bar item for quick controls (Play/Pause, Toggle Notch, Settings, Quit).
   - Dedicated Settings window with General, Features, Sound & Haptics, and Freedom tabs.

---

## 🛠️ Project Structure

```text
/Users/rittvikvashishtha/Notch/
├── OpenAlcove.app/                # Compiled and signed native macOS application bundle
├── Package.swift                  # Swift Package Manager manifest
├── Scripts/
│   └── build_app.sh              # One-click release build and code-signing script
└── Sources/
    ├── main.swift                 # Application entry point
    ├── App/
    │   └── AppDelegate.swift      # Menu bar status item, window management
    ├── Core/
    │   ├── NotchPanel.swift       # NSPanel implementation (REA Hopper decompiled)
    │   ├── ScreenGeometry.swift   # Notch detection & safeAreaInsets measurement
    │   └── SoundManager.swift     # Audio player & haptic sound engine
    ├── Features/
    │   ├── Media/
    │   │   ├── MediaRemoteBridge.swift # MediaRemote dynamic loader & notifications
    │   │   ├── MediaManager.swift      # Playback state & metadata model
    │   │   ├── WaveformView.swift      # Animated audio waveform
    │   │   └── MarqueeText.swift       # Smooth scrolling marquee text
    │   ├── HUD/
    │   │   ├── VolumeManager.swift     # CoreAudio listener & volume HUD
    │   │   └── BrightnessManager.swift # DisplayServices brightness listener
    │   ├── Battery/
    │   │   └── BatteryManager.swift    # IOPowerSources battery & charging HUD
    │   ├── Bluetooth/
    │   │   └── BluetoothManager.swift  # IOBluetooth & AirPods battery gauges
    │   ├── Shelf/
    │   │   └── ShelfDropzoneView.swift # Drag-and-drop notch shelf
    │   └── Calendar/
    │       └── CalendarQuickView.swift # Calendar schedule & clock
    ├── UI/
    │   ├── NotchContentView.swift      # Main state machine & spring animations
    │   ├── NotchCompactView.swift      # Compact notch wings & live activities
    │   ├── NotchExpandedView.swift     # Drop-down card with media, HUDs, AirPods, shelf
    │   └── Settings/
    │       ├── AppSettings.swift       # Persistent user preferences
    │       └── SettingsView.swift      # Modern macOS Settings window
    └── Resources/
        ├── Sounds/                     # Native sound effects (.caf, .m4a)
        └── Videos/                     # AirPods animation assets
```

---

## 🚀 Building & Running

### Run the App
The application is pre-built, signed, and currently active on your Mac:
```bash
open /Users/rittvikvashishtha/Notch/OpenAlcove.app
```

### Recompile from Source
To rebuild the application after making any modifications:
```bash
/Users/rittvikvashishtha/Notch/Scripts/build_app.sh
```
or with Swift Package Manager:
```bash
swift build -c release
```

---

## 🔒 100% Free Forever
- **No License Keys** (`LicenseManager` bypassed).
- **No Trial Periods** (No 7-day expiration).
- **No Network Phone-Home** (100% offline and privacy-respecting).
- **All Pro Features Unlocked**.
