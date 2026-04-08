import Foundation
import AppKit
import Carbon
import Combine

@available(macOS 14.0, *)
class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    
    @Published var lastPressedKey: String?
    
    private init() {
        registerEventHandler()
    }
    
    deinit {
        unregisterAllHotKeys()
    }
    
    // MARK: - Event Handler
    
    private func registerEventHandler() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let callback: EventHandlerUPP = { _, eventRef, userData -> OSStatus in
            guard let eventRef = eventRef else { return noErr }
            
            var hotKeyID = EventHotKeyID()
            let result = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if result == noErr {
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
                manager.handleHotKeyPress(id: hotKeyID.id)
            }
            
            return noErr
        }
        
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventType, userData, &eventHandler)
    }
    
    // MARK: - Hot Key Registration
    
    func registerHotKey(
        keyCode: UInt32,
        modifiers: UInt32,
        identifier: UInt32,
        action: @escaping () -> Void
    ) -> Bool {
        unregisterHotKey(identifier: identifier)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(fourCharCode("CRTM"))
        hotKeyID.id = identifier
        
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[identifier] = ref
            return true
        }
        
        return false
    }
    
    func unregisterHotKey(identifier: UInt32) {
        if let ref = hotKeyRefs[identifier] {
            UnregisterEventHotKey(ref)
            hotKeyRefs.removeValue(forKey: identifier)
        }
    }
    
    func unregisterAllHotKeys() {
        for (id, _) in hotKeyRefs {
            unregisterHotKey(identifier: id)
        }
        hotKeyRefs.removeAll()
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
    
    // MARK: - Hot Key Handling
    
    private var hotKeyActions: [UInt32: () -> Void] = [:]
    
    func registerAction(for identifier: UInt32, action: @escaping () -> Void) {
        hotKeyActions[identifier] = action
    }
    
    private func handleHotKeyPress(id: UInt32) {
        DispatchQueue.main.async { [weak self] in
            self?.lastPressedKey = String(id)
            self?.hotKeyActions[id]?()
        }
    }
    
    // MARK: - Convenience Methods
    
    func registerQuickAddTimerHotKey(action: @escaping () -> Void) {
        // Cmd + Option + T
        let keyCode = UInt32(kVK_ANSI_T)
        let modifiers = UInt32(cmdKey | optionKey)
        let identifier: UInt32 = 1
        
        if registerHotKey(keyCode: keyCode, modifiers: modifiers, identifier: identifier, action: action) {
            registerAction(for: identifier, action: action)
            print("已注册快速添加倒计时快捷键: Cmd+Option+T")
        }
    }
    
    func registerPauseResumeHotKey(action: @escaping () -> Void) {
        // Cmd + Option + P
        let keyCode = UInt32(kVK_ANSI_P)
        let modifiers = UInt32(cmdKey | optionKey)
        let identifier: UInt32 = 2
        
        if registerHotKey(keyCode: keyCode, modifiers: modifiers, identifier: identifier, action: action) {
            registerAction(for: identifier, action: action)
            print("已注册暂停/继续快捷键: Cmd+Option+P")
        }
    }
    
    func registerStopHotKey(action: @escaping () -> Void) {
        // Cmd + Option + S
        let keyCode = UInt32(kVK_ANSI_S)
        let modifiers = UInt32(cmdKey | optionKey)
        let identifier: UInt32 = 3
        
        if registerHotKey(keyCode: keyCode, modifiers: modifiers, identifier: identifier, action: action) {
            registerAction(for: identifier, action: action)
            print("已注册停止快捷键: Cmd+Option+S")
        }
    }
    
    func registerShowWindowHotKey(action: @escaping () -> Void) {
        // Cmd + Option + M
        let keyCode = UInt32(kVK_ANSI_M)
        let modifiers = UInt32(cmdKey | optionKey)
        let identifier: UInt32 = 4
        
        if registerHotKey(keyCode: keyCode, modifiers: modifiers, identifier: identifier, action: action) {
            registerAction(for: identifier, action: action)
            print("已注册显示窗口快捷键: Cmd+Option+M")
        }
    }
}

// MARK: - Helper Extensions

private func fourCharCode(_ string: String) -> FourCharCode {
    guard string.count == 4 else { return 0 }
    var result: FourCharCode = 0
    for char in string.utf8 {
        result = (result << 8) + FourCharCode(char)
    }
    return result
}

// MARK: - Key Codes

private let kVK_ANSI_T: Int = 0x11
private let kVK_ANSI_P: Int = 0x23
private let kVK_ANSI_S: Int = 0x01
private let kVK_ANSI_M: Int = 0x2E
