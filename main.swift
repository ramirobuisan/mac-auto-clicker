import SwiftUI
import ApplicationServices
import Carbon
import Combine

// MARK: - Enums & Models

enum ActivationMode: Int, CaseIterable, Identifiable {
    case toggle = 0
    case holdHotkey = 1
    case holdMouse = 2
    
    var id: Int { self.rawValue }
    var description: String {
        switch self {
        case .toggle: return "Toggle"
        case .holdHotkey: return "Hold Hotkey"
        case .holdMouse: return "Hold Mouse"
        }
    }
}

enum TriggerMouseButton: Int, CaseIterable, Identifiable {
    case middle = 0
    case right = 1
    case left = 2
    
    var id: Int { self.rawValue }
    var description: String {
        switch self {
        case .middle: return "Middle Button"
        case .right: return "Right Button"
        case .left: return "Left Button"
        }
    }
}

enum ClickLocationMode: Int, CaseIterable, Identifiable {
    case current = 0
    case fixed = 1
    
    var id: Int { self.rawValue }
    var description: String {
        switch self {
        case .current: return "Current Location"
        case .fixed: return "Fixed Coordinates"
        }
    }
}

enum MouseButtonType: Int, CaseIterable, Identifiable {
    case left = 0
    case right = 1
    case center = 2
    
    var id: Int { self.rawValue }
    var name: String {
        switch self {
        case .left: return "Left Click"
        case .right: return "Right Click"
        case .center: return "Middle Click"
        }
    }
    
    var cgButton: CGMouseButton {
        switch self {
        case .left: return .left
        case .right: return .right
        case .center: return .center
        }
    }
}

enum ClickType: Int, CaseIterable, Identifiable {
    case single = 0
    case double = 1
    
    var id: Int { self.rawValue }
    var name: String {
        switch self {
        case .single: return "Single"
        case .double: return "Double"
        }
    }
}

// MARK: - Carbon Hotkey Bridge

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    
    // Low-level C callback for Carbon events
    private let hotKeyHandler: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        if status == noErr {
            let eventKind = GetEventKind(event)
            let isPressed = eventKind == UInt32(kEventHotKeyPressed)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("GlobalHotKeyPressed"), object: nil, userInfo: ["id": hotKeyID.id, "isPressed": isPressed])
            }
        }
        return noErr
    }
    
    func register(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        unregister()
        
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        let target = GetApplicationEventTarget()
        
        let statusHandler = InstallEventHandler(target, hotKeyHandler, 2, &eventTypes, nil, &handlerRef)
        guard statusHandler == noErr else {
            print("Failed to install Carbon event handler: \(statusHandler)")
            return
        }
        
        let hotKeyID = EventHotKeyID(signature: OSType(12345), id: id)
        let statusHotkey = RegisterEventHotKey(keyCode, modifiers, hotKeyID, target, 0, &hotKeyRef)
        if statusHotkey != noErr {
            print("Failed to register Carbon hotkey: \(statusHotkey)")
        }
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
    }
}

// MARK: - UI Hotkey Manager

class UIHotkeyManager: ObservableObject {
    @Published var keyCode: UInt32 = 97 { // Default F6 (keyCode 97)
        didSet {
            registerCurrent()
        }
    }
    @Published var modifiers: UInt32 = 0 {
        didSet {
            registerCurrent()
        }
    }
    @Published var hotkeyName: String = "F6"
    @Published var isRecording = false
    
    func registerCurrent() {
        HotkeyManager.shared.register(keyCode: keyCode, modifiers: modifiers, id: 1)
    }
    
    func updateHotkey(keyCode: UInt32, modifiers: UInt32, name: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.hotkeyName = name
    }
    
    static func carbonModifiers(from cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if cocoaFlags.contains(.command) { carbonFlags |= 256 }
        if cocoaFlags.contains(.shift) { carbonFlags |= 512 }
        if cocoaFlags.contains(.option) { carbonFlags |= 2048 }
        if cocoaFlags.contains(.control) { carbonFlags |= 4096 }
        return carbonFlags
    }
    
    static func modifierString(from cocoaFlags: NSEvent.ModifierFlags) -> String {
        var str = ""
        if cocoaFlags.contains(.control) { str += "⌃" }
        if cocoaFlags.contains(.option) { str += "⌥" }
        if cocoaFlags.contains(.shift) { str += "⇧" }
        if cocoaFlags.contains(.command) { str += "⌘" }
        return str
    }
    
    static func keyString(from keyCode: UInt16) -> String {
        switch keyCode {
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 53: return "Esc"
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 123: return "Left"
        case 124: return "Right"
        case 125: return "Down"
        case 126: return "Up"
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"
        case 29: return "0"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        default:
            return "Key \(keyCode)"
        }
    }
}

// MARK: - Clicker Engine

class ClickerEngine: ObservableObject {
    @Published var isActive = false
    
    // Configurable parameters
    @Published var hour = 0 {
        didSet { if !isUpdating { syncCPS() } }
    }
    @Published var minute = 0 {
        didSet { if !isUpdating { syncCPS() } }
    }
    @Published var second = 0 {
        didSet { if !isUpdating { syncCPS() } }
    }
    @Published var millisecond = 100 { // Default 100ms
        didSet { if !isUpdating { syncCPS() } }
    }
    @Published var cps: Double = 10.0 { // Default 10 CPS
        didSet { if !isUpdating { syncInterval() } }
    }
    
    private var isUpdating = false
    
    private func syncCPS() {
        isUpdating = true
        let totalMs = Double(hour * 3600000 + minute * 60000 + second * 1000 + millisecond)
        if totalMs > 0 {
            let newCps = Double(round((1000.0 / totalMs) * 100.0) / 100.0)
            if self.cps != newCps {
                self.cps = newCps
            }
        }
        isUpdating = false
    }
    
    private func syncInterval() {
        isUpdating = true
        if cps > 0 {
            let totalMs = 1000.0 / cps
            let ms = max(1, Int(round(totalMs)))
            
            let newHour = ms / 3600000
            let newMinute = (ms % 3600000) / 60000
            let newSecond = (ms % 60000) / 1000
            let newMillisecond = ms % 1000
            
            if self.hour != newHour { self.hour = newHour }
            if self.minute != newMinute { self.minute = newMinute }
            if self.second != newSecond { self.second = newSecond }
            if self.millisecond != newMillisecond { self.millisecond = newMillisecond }
        }
        isUpdating = false
    }
    
    @Published var selectedButton: MouseButtonType = .left
    @Published var selectedClickType: ClickType = .single
    @Published var holdDurationMs: Double = 10.0 // Default hold 10ms
    @Published var useJitter = false
    @Published var activationMode: ActivationMode = .toggle
    @Published var triggerButton: TriggerMouseButton = .middle
    
    @Published var clickLocationMode: ClickLocationMode = .current
    @Published var fixedPoint: CGPoint = .zero
    
    @Published var repeatCountMode: Int = 0 // 0: Infinite, 1: Set limit
    @Published var clickLimit: Int = 10
    
    private var clickCount = 0
    private var workItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.macautoclicker.engine", qos: .userInteractive)
    
    // Total interval in milliseconds
    var intervalMs: Double {
        let total = Double(hour * 3600000 + minute * 60000 + second * 1000 + millisecond)
        return max(1.0, total) // Prevent zero/negative intervals
    }
    
    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }
    
    func start() {
        guard !isActive else { return }
        isActive = true
        clickCount = 0
        scheduleNextClick()
    }
    
    func stop() {
        guard isActive else { return }
        isActive = false
        workItem?.cancel()
        workItem = nil
    }
    
    private func scheduleNextClick() {
        guard isActive else { return }
        
        let currentInterval = useJitter
            ? intervalMs * Double.random(in: 0.9...1.1)
            : intervalMs
        
        let item = DispatchWorkItem { [weak self] in
            guard let self = self, self.isActive else { return }
            
            self.executeClick()
            self.clickCount += 1
            
            if self.repeatCountMode == 1, self.clickCount >= self.clickLimit {
                DispatchQueue.main.async {
                    self.stop()
                }
                return
            }
            
            self.scheduleNextClick()
        }
        
        self.workItem = item
        queue.asyncAfter(deadline: .now() + .milliseconds(Int(currentInterval)), execute: item)
    }
    
    private func executeClick() {
        // Resolve target coordinate
        let targetPoint: CGPoint
        switch clickLocationMode {
        case .current:
            guard let currentLoc = CGEvent(source: nil)?.location else { return }
            targetPoint = currentLoc
        case .fixed:
            targetPoint = fixedPoint
        }
        
        let source = CGEventSource(stateID: .combinedSessionState)
        let cgButton = selectedButton.cgButton
        
        var downType: CGEventType
        var upType: CGEventType
        
        switch selectedButton {
        case .left:
            downType = .leftMouseDown
            upType = .leftMouseUp
        case .right:
            downType = .rightMouseDown
            upType = .rightMouseUp
        case .center:
            downType = .otherMouseDown
            upType = .otherMouseUp
        }
        
        if selectedClickType == .double {
            // First Click
            let down1 = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: targetPoint, mouseButton: cgButton)
            let up1 = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: targetPoint, mouseButton: cgButton)
            down1?.setIntegerValueField(.mouseEventClickState, value: 1)
            down1?.setIntegerValueField(.eventSourceUserData, value: 12345)
            up1?.setIntegerValueField(.mouseEventClickState, value: 1)
            up1?.setIntegerValueField(.eventSourceUserData, value: 12345)
            
            down1?.post(tap: .cghidEventTap)
            if holdDurationMs > 0 { Thread.sleep(forTimeInterval: holdDurationMs / 1000.0) }
            up1?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.04) // Small delay between double clicks
            
            // Second Click
            let down2 = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: targetPoint, mouseButton: cgButton)
            let up2 = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: targetPoint, mouseButton: cgButton)
            down2?.setIntegerValueField(.mouseEventClickState, value: 2)
            down2?.setIntegerValueField(.eventSourceUserData, value: 12345)
            up2?.setIntegerValueField(.mouseEventClickState, value: 2)
            up2?.setIntegerValueField(.eventSourceUserData, value: 12345)
            
            down2?.post(tap: .cghidEventTap)
            if holdDurationMs > 0 { Thread.sleep(forTimeInterval: holdDurationMs / 1000.0) }
            up2?.post(tap: .cghidEventTap)
        } else {
            // Single Click
            let down = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: targetPoint, mouseButton: cgButton)
            down?.setIntegerValueField(.mouseEventClickState, value: 1)
            down?.setIntegerValueField(.eventSourceUserData, value: 12345)
            down?.post(tap: .cghidEventTap)
            
            if holdDurationMs > 0 { Thread.sleep(forTimeInterval: holdDurationMs / 1000.0) }
            
            let up = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: targetPoint, mouseButton: cgButton)
            up?.setIntegerValueField(.mouseEventClickState, value: 1)
            up?.setIntegerValueField(.eventSourceUserData, value: 12345)
            up?.post(tap: .cghidEventTap)
        }
    }
}

// MARK: - Subviews

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct IntervalField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            TextField("", value: $value, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
                .frame(width: 58)
                .onSubmit {
                    if !range.contains(value) {
                        value = max(range.lowerBound, min(range.upperBound, value))
                    }
                }
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @EnvironmentObject var engine: ClickerEngine
    @EnvironmentObject var hotkeyMgr: UIHotkeyManager
    
    @State private var isAccessibilityTrusted = AXIsProcessTrusted()
    @State private var isPicking = false
    @State private var cornerStoppingTimer: Timer?
    @State private var pulseAnimation = false
    @State private var inputMode = 0 // 0: Time, 1: CPS
    
    @State private var globalMonitor: Any?
    @State private var localMonitor: Any?
    @State private var mouseGlobalMonitor: Any?
    @State private var mouseLocalMonitor: Any?
    @State private var recordingMonitor: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            // Custom Title Bar
            HStack {
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.purple)
                Text("MAC AUTO CLICKER")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                
                // Active Pulse Indicator
                if engine.isActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0.6 : 1.0)
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseAnimation = true
                        }
                    }
                    .onDisappear {
                        pulseAnimation = false
                    }
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                        Text("READY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            
            // Check Accessibility Permissions
            if !isAccessibilityTrusted {
                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accessibility Access Needed")
                                .font(.system(size: 12, weight: .bold))
                            Text("To simulate clicks in other apps, macOS requires Accessibility permission. Click below to grant it.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: openAccessibilitySettings) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text("Grant Permission")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding(12)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    
                    // Speed / Interval Group
                    GroupBox(label: Label("Click Speed / Interval", systemImage: "timer").font(.system(size: 11, weight: .bold))) {
                        VStack(spacing: 12) {
                            Picker("", selection: $inputMode) {
                                Text("Time Interval").tag(0)
                                Text("CPS Mode").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.bottom, 4)
                            
                            if inputMode == 0 {
                                HStack(spacing: 8) {
                                    IntervalField(label: "Hours", value: $engine.hour, range: 0...23)
                                    IntervalField(label: "Mins", value: $engine.minute, range: 0...59)
                                    IntervalField(label: "Secs", value: $engine.second, range: 0...59)
                                    IntervalField(label: "Ms", value: $engine.millisecond, range: 1...999)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Clicks Per Second")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.1f CPS", engine.cps))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    Spacer()
                                    Slider(value: $engine.cps, in: 0.1...100.0, step: 0.5)
                                        .frame(width: 120)
                                    
                                    TextField("", value: $engine.cps, format: .number)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 6)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(6)
                                        .frame(width: 58)
                                        .onSubmit {
                                            if engine.cps < 0.1 { engine.cps = 0.1 }
                                            if engine.cps > 1000.0 { engine.cps = 1000.0 }
                                        }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Button & Click Type Group
                    GroupBox(label: Label("Click Settings", systemImage: "slider.horizontal.3").font(.system(size: 11, weight: .bold))) {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Mouse Button")
                                    .font(.system(size: 11))
                                Spacer()
                                Picker("", selection: $engine.selectedButton) {
                                    ForEach(MouseButtonType.allCases) { type in
                                        Text(type.name).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140)
                            }
                            
                            HStack {
                                Text("Click Type")
                                    .font(.system(size: 11))
                                Spacer()
                                Picker("", selection: $engine.selectedClickType) {
                                    ForEach(ClickType.allCases) { type in
                                        Text(type.name).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hold Duration")
                                        .font(.system(size: 11))
                                    Text("\(Int(engine.holdDurationMs)) ms")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Slider(value: $engine.holdDurationMs, in: 0...500, step: 5)
                                    .frame(width: 140)
                            }
                            
                            Toggle(isOn: $engine.useJitter) {
                                Text("Jitter (Randomize Speed +/- 10%)")
                                    .font(.system(size: 11))
                            }
                            .toggleStyle(.checkbox)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Location Group
                    GroupBox(label: Label("Click Position", systemImage: "mappin.and.ellipse").font(.system(size: 11, weight: .bold))) {
                        VStack(spacing: 10) {
                            Picker("", selection: $engine.clickLocationMode) {
                                ForEach(ClickLocationMode.allCases) { mode in
                                    Text(mode.description).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            if engine.clickLocationMode == .fixed {
                                HStack {
                                    if isPicking {
                                        Text("Hover cursor & press SPACE")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.purple)
                                            .opacity(pulseAnimation ? 0.5 : 1.0)
                                    } else {
                                        Text("X: \(Int(engine.fixedPoint.x))   Y: \(Int(engine.fixedPoint.y))")
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(isPicking ? "Cancel" : "Pick Location") {
                                        if isPicking {
                                            stopPicking()
                                        } else {
                                            startPicking()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.purple)
                                    .font(.system(size: 11))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Repeat Group
                    GroupBox(label: Label("Repeat Options", systemImage: "arrow.2.squarepath").font(.system(size: 11, weight: .bold))) {
                        HStack(spacing: 12) {
                            Picker("", selection: $engine.repeatCountMode) {
                                Text("Infinite").tag(0)
                                Text("Fixed").tag(1)
                            }
                            .pickerStyle(.segmented)
                            
                            if engine.repeatCountMode == 1 {
                                TextField("Count", value: $engine.clickLimit, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Global Hotkey Group
                    GroupBox(label: Label("Start / Stop Hotkey", systemImage: "keyboard").font(.system(size: 11, weight: .bold))) {
                        HStack {
                            Text("Global Hotkey")
                                .font(.system(size: 11))
                            Spacer()
                            
                            Button(action: {
                                if hotkeyMgr.isRecording {
                                    stopRecording()
                                } else {
                                    hotkeyMgr.isRecording = true
                                    startRecording()
                                }
                            }) {
                                Text(hotkeyMgr.isRecording ? "Press a Key..." : hotkeyMgr.hotkeyName)
                                    .frame(width: 130)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                            .buttonStyle(.bordered)
                            .tint(hotkeyMgr.isRecording ? .red : .purple)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Activation Mode Group
                    GroupBox(label: Label("Activation Mode", systemImage: "hand.tap").font(.system(size: 11, weight: .bold))) {
                        VStack(spacing: 8) {
                            Picker("", selection: $engine.activationMode) {
                                ForEach(ActivationMode.allCases) { mode in
                                    Text(mode.description).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            if engine.activationMode == .holdMouse {
                                HStack {
                                    Text("Trigger Mouse Button")
                                        .font(.system(size: 11))
                                    Spacer()
                                    Picker("", selection: $engine.triggerButton) {
                                        ForEach(TriggerMouseButton.allCases) { button in
                                            Text(button.description).tag(button)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer(minLength: 4)
            
            // Bottom Toggler Button
            Button(action: { engine.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: engine.isActive ? "stop.fill" : "play.fill")
                    Text(engine.isActive ? "STOP" : "START")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(engine.isActive ? .red : .purple)
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(WindowAccessor { window in
            window.level = .floating // Keep always on top
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.styleMask.insert(.resizable)
            window.standardWindowButton(.zoomButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("GlobalHotKeyPressed"))) { notification in
            guard let userInfo = notification.userInfo,
                  let isPressed = userInfo["isPressed"] as? Bool else {
                engine.toggle()
                return
            }
            
            switch engine.activationMode {
            case .toggle:
                if isPressed {
                    engine.toggle()
                }
            case .holdHotkey:
                if isPressed {
                    engine.start()
                } else {
                    engine.stop()
                }
            case .holdMouse:
                break // Managed by mouse monitors
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // Corner stopping check
            if engine.isActive {
                checkCornerStopping()
            }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            // Regular check for Accessibility
            isAccessibilityTrusted = AXIsProcessTrusted()
        }
        .onAppear {
            hotkeyMgr.registerCurrent()
            setupMouseMonitors()
        }
        .onDisappear {
            HotkeyManager.shared.unregister()
            clearMouseMonitors()
            stopRecording()
            stopPicking()
        }
        .onChange(of: engine.activationMode) { _ in
            setupMouseMonitors()
        }
        .onChange(of: engine.triggerButton) { _ in
            setupMouseMonitors()
        }
    }
    
    // MARK: - Actions
    
    func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    func checkCornerStopping() {
        let mouseLoc = NSEvent.mouseLocation
        let tolerance: CGFloat = 10.0
        
        for screen in NSScreen.screens {
            let f = screen.frame
            let topLeft = CGPoint(x: f.minX, y: f.maxY)
            let topRight = CGPoint(x: f.maxX, y: f.maxY)
            let bottomLeft = CGPoint(x: f.minX, y: f.minY)
            let bottomRight = CGPoint(x: f.maxX, y: f.minY)
            
            func near(_ p1: CGPoint, _ p2: CGPoint) -> Bool {
                return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2)) < tolerance
            }
            
            if near(mouseLoc, topLeft) || near(mouseLoc, topRight) || near(mouseLoc, bottomLeft) || near(mouseLoc, bottomRight) {
                engine.stop()
                break
            }
        }
    }
    
    func startPicking() {
        isPicking = true
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Spacebar
                captureLocation()
            }
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Spacebar
                captureLocation()
                return nil // swallow space event
            }
            return event
        }
    }
    
    func captureLocation() {
        if let loc = CGEvent(source: nil)?.location {
            DispatchQueue.main.async {
                engine.fixedPoint = loc
                self.stopPicking()
            }
        }
    }
    
    func stopPicking() {
        isPicking = false
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    func startRecording() {
        stopRecording()
        
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            let code = UInt32(event.keyCode)
            let cocoaFlags = event.modifierFlags
            let carbonFlags = UIHotkeyManager.carbonModifiers(from: cocoaFlags)
            
            let modStr = UIHotkeyManager.modifierString(from: cocoaFlags)
            let keyStr = UIHotkeyManager.keyString(from: event.keyCode)
            let fullName = modStr + keyStr
            
            DispatchQueue.main.async {
                hotkeyMgr.updateHotkey(keyCode: code, modifiers: carbonFlags, name: fullName)
                self.stopRecording()
            }
            return nil // swallow event
        }
    }
    
    func stopRecording() {
        hotkeyMgr.isRecording = false
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
    }
    
    func setupMouseMonitors() {
        clearMouseMonitors()
        
        guard engine.activationMode == .holdMouse else { return }
        
        var mask: NSEvent.EventTypeMask = []
        switch engine.triggerButton {
        case .middle:
            mask = [.otherMouseDown, .otherMouseUp]
        case .right:
            mask = [.rightMouseDown, .rightMouseUp]
        case .left:
            mask = [.leftMouseDown, .leftMouseUp]
        }
        
        mouseGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
            handleMouseEvent(event)
        }
        
        mouseLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            handleMouseEvent(event)
            return event
        }
    }
    
    func clearMouseMonitors() {
        if let monitor = mouseGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            mouseGlobalMonitor = nil
        }
        if let monitor = mouseLocalMonitor {
            NSEvent.removeMonitor(monitor)
            mouseLocalMonitor = nil
        }
    }
    
    func handleMouseEvent(_ event: NSEvent) {
        if let cgEvent = event.cgEvent, cgEvent.getIntegerValueField(.eventSourceUserData) == 12345 {
            return
        }
        
        let isDown: Bool
        let eventType = event.type
        
        switch engine.triggerButton {
        case .middle:
            isDown = eventType == .otherMouseDown && event.buttonNumber == 2
        case .right:
            isDown = eventType == .rightMouseDown
        case .left:
            isDown = eventType == .leftMouseDown
        }
        
        let isUp: Bool
        switch engine.triggerButton {
        case .middle:
            isUp = eventType == .otherMouseUp && event.buttonNumber == 2
        case .right:
            isUp = eventType == .rightMouseUp
        case .left:
            isUp = eventType == .leftMouseUp
        }
        
        if isDown {
            DispatchQueue.main.async {
                engine.start()
            }
        } else if isUp {
            DispatchQueue.main.async {
                engine.stop()
            }
        }
    }
}

// MARK: - App Entry Point

@main
struct MacAutoClickerApp: App {
    @StateObject private var engine = ClickerEngine()
    @StateObject private var hotkeyMgr = UIHotkeyManager()
    
    var body: some Scene {
        Window("Mac Auto Clicker", id: "main") {
            ContentView()
                .environmentObject(engine)
                .environmentObject(hotkeyMgr)
                .frame(minWidth: 320, idealWidth: 345, maxWidth: 600, minHeight: 460, idealHeight: 520, maxHeight: 1000)
                .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)
    }
}
