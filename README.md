# 🖱️ Mac Auto Clicker (Premium Edition)

A high-performance, native macOS auto clicker written in Swift using SwiftUI. Featuring a modern, resizable floating glassmorphic interface, global hotkeys, randomized click jitter, hold duration control, and screen corner fail-safes.

---

## ✨ Features

- **🎨 Modern Glassmorphic UI**: Translucent floating utility panel designed specifically for macOS with smooth micro-animations.
- **🔄 Dual Input Speed Modes**: 
  - **Time Interval**: Set hours, minutes, seconds, and milliseconds.
  - **CPS Mode**: Slide or type a clicks-per-second value (0.1 to 1000.0 CPS). Both modes synchronize bidirectionally in real-time.
- **⚡ High-Precision Clicking Engine**: Utilizes macOS `CGEvent` simulation running on a dedicated background interactive queue (`com.macautoclicker.engine`) to prevent UI lag.
- **🖱️ Mouse Configurations**:
  - Support for **Left**, **Right**, and **Middle** click inputs.
  - **Single** or **Double** click sequences.
- **🛡️ Safety & Anti-Detection Options**:
  - **Hold Duration**: Adjust how long the simulated click is held down (0 to 500ms).
  - **Jitter**: Randomizes click speed by +/- 10% on the fly to bypass detection mechanisms.
  - **Corner Stopping**: Instant fail-safe that stops the clicker if the mouse cursor is thrown into any of the 4 screen corners.
- **📍 Precise Coordinate Picking**: Choose to click at the current cursor position or define fixed screen coordinates using a dynamic picker (Hover + Spacebar key capture).
- **🔁 Repeat Limits**: Toggle between infinite clicking or setting a fixed repeat count limit.
- **⌨️ Global Hotkeys**: Carbon API-based hotkey listener to start/stop the clicking engine from anywhere on your Mac (supports F1–F12 keys and custom combinations).
- **📏 Resizable & Sticky**: Window can be dynamically resized and remains floating on top of all other windows.

---

## 🛠️ Build & Installation

### Requirements
- macOS 13.0 or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Swift Compiler (`swiftc` via Xcode or Command Line Tools)

### Build and Launch
Clone the repository and run the compilation script in your terminal:

```bash
# Clone the repository
git clone https://github.com/ramirobuisan/mac-auto-clicker.git
cd mac-auto-clicker

# Build and run the app
./run.sh
```

---

## 🚀 Setup & Usage

### 1. Grant Accessibility Permissions
Because macOS restricts applications from injecting mouse events globally:
1. Launch the application.
2. Click **Grant Permission** in the yellow alert card.
3. This opens **System Settings > Privacy & Security > Accessibility**.
4. Enable **MacAutoClicker** in the list. The warning card in the app will automatically dismiss.

### 2. Basic Configuration
- Select **Time Interval** or **CPS Mode** and set your target speed.
- Choose the mouse button and click type.
- Toggle between **Current Location** (clicks wherever your mouse is focused) or **Fixed Coordinates** (click *Pick Location*, hover, and press `Spacebar` to lock coordinates).
- Press your global hotkey (default is **`F6`**) or click the **START/STOP** button to toggle the clicker.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
