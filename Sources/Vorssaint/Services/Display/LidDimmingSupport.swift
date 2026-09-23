// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import IOKit.hidsystem

/// Captures and restores display and keyboard brightness for the closed-lid
/// dimming option.
enum LidDimmingSupport {
    // MARK: - Displays, over the same DisplayServices route `BrightnessBridge`
    // already resolves for the built-in panel and Apple external displays.
    // Third-party monitors driven only over DDC are out of scope, like the
    // rest of that route.

    /// The main display plus every other display CoreGraphics reports active.
    /// `CGMainDisplayID()` is included explicitly because the built-in panel
    /// drops out of the active list once the lid physically closes.
    static func knownDisplayIDs() -> [CGDirectDisplayID] {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        CGGetActiveDisplayList(16, &ids, &count)
        var result = Array(ids.prefix(Int(count)))
        let main = CGMainDisplayID()
        if !result.contains(main) { result.insert(main, at: 0) }
        return result
    }

    static func captureBrightnesses() -> [(CGDirectDisplayID, Double)] {
        guard let getBrightness = BrightnessBridge.getBrightness else { return [] }
        return knownDisplayIDs().compactMap { id in
            var value: Float = 0
            guard getBrightness(id, &value) == 0 else { return nil }
            return (id, Double(value))
        }
    }

    static func dimToZero() {
        guard let setBrightness = BrightnessBridge.setBrightness else { return }
        for id in knownDisplayIDs() { _ = setBrightness(id, 0) }
    }

    static func restore(_ saved: [(CGDirectDisplayID, Double)]) {
        guard let setBrightness = BrightnessBridge.setBrightness else { return }
        for (id, value) in saved { _ = setBrightness(id, Float(value)) }
    }

    // MARK: - Keyboard backlight, over the older `IOHIDSystem` illumination
    // parameter instead of CoreBrightness's `KeyboardBrightnessClient`
    // (`BrightnessService.sharedKeyboardLightBridge`). That client is built
    // for a slider or hotkey a person is actively driving and briefly
    // suspends the system's own idle-dimming timer around the write; a
    // restore fired by the lid opening has no key press of its own to keep
    // that timer from having already expired, so the value it just wrote
    // loses to it almost immediately. Setting the raw HID parameter directly
    // never goes through that idle-dimming layer at all.

    private static let keyboardIlluminationKey = "HIDKeyboardIlluminationValue" as CFString

    // `IOHIDGetParameter`/`IOHIDSetParameter` are deprecated but have no
    // replacement for this key. Resolved through `dlopen`/`dlsym`, like every
    // other raw IOKit or private-framework call in this file's sibling
    // `BrightnessBridge`, so the calls carry no deprecation warning and the
    // feature degrades to a no-op if a future OS ever drops the symbols.
    private typealias GetParameterFn = @convention(c)
        (io_connect_t, CFString, IOByteCount, UnsafeMutableRawPointer, UnsafeMutablePointer<IOByteCount>) -> kern_return_t
    private typealias SetParameterFn = @convention(c)
        (io_connect_t, CFString, UnsafeRawPointer, IOByteCount) -> kern_return_t

    private static let ioKitHandle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY)
    private static let getParameter: GetParameterFn? = {
        guard let ioKitHandle, let symbol = dlsym(ioKitHandle, "IOHIDGetParameter") else { return nil }
        return unsafeBitCast(symbol, to: GetParameterFn.self)
    }()
    private static let setParameter: SetParameterFn? = {
        guard let ioKitHandle, let symbol = dlsym(ioKitHandle, "IOHIDSetParameter") else { return nil }
        return unsafeBitCast(symbol, to: SetParameterFn.self)
    }()

    private static func openHIDConnection() -> io_connect_t? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }
        var connect: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == KERN_SUCCESS
        else { return nil }
        return connect
    }

    static func captureKeyboardBrightness() -> Double? {
        guard let connect = openHIDConnection(), let getParameter else { return nil }
        defer { IOServiceClose(connect) }
        var value: Float = 0
        var size = IOByteCount(MemoryLayout<Float>.size)
        let result = withUnsafeMutablePointer(to: &value) {
            getParameter(connect, keyboardIlluminationKey, IOByteCount(MemoryLayout<Float>.size), $0, &size)
        }
        guard result == KERN_SUCCESS else { return nil }
        return Double(value)
    }

    static func setKeyboardBrightness(_ value: Double) {
        guard let connect = openHIDConnection(), let setParameter else { return }
        defer { IOServiceClose(connect) }
        var v = Float(value)
        _ = withUnsafePointer(to: &v) {
            setParameter(connect, keyboardIlluminationKey, $0, IOByteCount(MemoryLayout<Float>.size))
        }
    }
}
