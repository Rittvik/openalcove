# OpenAlcove 🏔️

**OpenAlcove** is an open-source, 100% free re-engineering of the **Alcove** MacBook Pro notch application, reverse-engineered using the **REA (Reverse-Engineer-Anything)** framework with Hopper Disassembler and native macOS system frameworks.

All features that previously required a paid license or expired after a trial are **unlocked forever** and run completely on-device with zero telemetry, zero paywalls, and zero cloud dependencies.

---

## 📥 Download & Install

You can download the pre-built disk image installer directly from this repository:

👉 **[Download OpenAlcove.dmg](https://github.com/Rittvik/openalcove/raw/main/OpenAlcove.dmg)**

### Quick Installation:
1. Download **`OpenAlcove.dmg`**.
2. Open the disk image.
3. Drag **`OpenAlcove.app`** into your **`Applications`** folder.
4. Launch OpenAlcove!

---

## ⚡ Key Features Rebuilt

1. **Hardware-Accurate Dynamic Notch Island**:
   - **Precise Hardware Alignment**: Measures `NSScreen.safeAreaInsets.top` and `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` to sit flush against the physical camera bezel.
   - **Glanceable Idle State**: When no media is playing, the closed notch displays the live **time** on the left wing and the **battery percentage / charging bolt** on the right wing.
   - **Virtual Notch Support**: Simulates a sleek dynamic island on non-notch Macs and external monitors.
   - **Native Window Behavior**: Floating window level `CGShieldingWindowLevel() + 1`, collection behavior `[.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]`, and non-activating panel (`canBecomeKey = false`) so it never steals keyboard focus.

2. **Now Playing Media Island**:
   - Real-time media playback integration with Spotify, Apple Music, YouTube (Safari/Chrome), Podcasts, and web audio.
   - **Live Artwork**: Album art extraction with rounded continuous corners.
   - **Marquee Text**: Automatically scrolls long track titles and artist names smoothly.
   - **Waveform Visualizer**: Multi-bar animated audio waveform that pulses in real time while audio is playing.
   - **Interactive Playback Controls**: Tactile Previous, Play/Pause, and Next track controls.
   - **Scrubbable Progress Bar**: Live elapsed time, remaining time, and progress visualization.

3. **System HUD Replacements**:
   - **Fluid Volume HUD**: Intercepts CoreAudio volume events (`AudioObjectAddPropertyListenerBlock`), blooms from the notch with a speaker icon and volume fill bar, accompanied by subtle volume tick feedback.
   - **Display Brightness HUD**: Monitors screen brightness (`DisplayServices.framework`) with sun icon and animated level.
   - **Charging & MagSafe Alert**: Triggers a green charging animation with battery percentage and Apple charging chime whenever USB-C or MagSafe is plugged in.

4. **AirPods & Bluetooth Audio Integration**:
   - Monitors connected devices via `IOBluetooth`.
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
openalcove/
├── OpenAlcove.dmg                 # Ready-to-use disk image installer
├── Package.swift                  # Swift Package Manager manifest
├── Scripts/
│   └── build_app.sh              # One-click release build, code-sign & DMG generation
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
    │   │   ├── MediaRemoteBridge.swift # Dual-engine media controller & Spotify bridge
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
    │   ├── NotchCompactView.swift      # Compact notch wings & idle time/battery
    │   ├── NotchExpandedView.swift     # Drop-down card with media, HUDs, AirPods, shelf
    │   └── Settings/
    │       ├── AppSettings.swift       # Persistent user preferences
    │       └── SettingsView.swift      # Modern macOS Settings window
    └── Resources/
        ├── Sounds/                     # Native sound effects (.caf, .m4a)
        └── Videos/                     # AirPods animation assets
```

---

## 🚀 Building from Source

To clone and compile the project locally:

```bash
git clone https://github.com/Rittvik/openalcove.git
cd openalcove
```

### Build App & DMG Installer
Run the build script to compile the release binary, package `OpenAlcove.app`, and create `OpenAlcove.dmg`:
```bash
./Scripts/build_app.sh
```

Or build with Swift Package Manager:
```bash
swift build -c release
```

---

## 🔒 100% Free Forever
- **No License Keys** (`LicenseManager` bypassed).
- **No Trial Periods** (No 7-day expiration).
- **No Network Phone-Home** (100% offline and privacy-respecting).
- **All Pro Features Unlocked**.
