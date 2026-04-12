import Foundation
import AppKit
import SwiftUI
import Combine
import os.log

@available(macOS 14.0, *)
@MainActor
final class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()

    private static let logger = Logger(subsystem: "com.foo.CountdownReminder", category: "MenuBarManager")

    @Published var isMenuOpen = false
    @Published var currentTimeString: String = ""
    @Published var shouldShowMainWindow = false

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var timerManager: TimerManager?
    private var cancellables = Set<AnyCancellable>()
    private var isConfigured = false
    private var mainWindow: NSWindow?

    private override init() {
        super.init()
    }

    func configure(with timerManager: TimerManager) {
        guard !isConfigured else {
            Self.logger.warning("MenuBarManager already configured, skipping duplicate initialization")
            return
        }

        isConfigured = true
        self.timerManager = timerManager
        setupMenuBar()
        setupObservers()
        Self.logger.info("MenuBarManager configured successfully")
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            Self.logger.error("Failed to create status bar button")
            return
        }

        button.action = #selector(handleClick)
        button.target = self

        // 一次性创建 popover 及其内容，避免每次点击都创建新实例
        let contentView = MenuBarPopoverView()
            .environmentObject(timerManager!)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        Self.logger.debug("Menu bar and popover initialized")
    }

    private func setupObservers() {
        guard let timerManager = timerManager else { return }

        timerManager.$activeTimers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        timerManager.$lastUpdateTimestamp
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)

        $shouldShowMainWindow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.performShowMainWindow()
                    self?.shouldShowMainWindow = false
                }
            }
            .store(in: &cancellables)
    }

    private func updateMenuBar() {
        guard let button = statusItem?.button,
              let timerManager = timerManager else { return }

        let activeTimers = timerManager.activeTimers
        let activeCount = activeTimers.count

        if activeCount == 0 {
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "倒计时提醒")
            button.image?.isTemplate = true
            currentTimeString = ""
        } else if activeCount == 1, let timer = activeTimers.first {
            let timeString = formatTimeForMenuBar(timer.remainingTime)
            button.attributedTitle = createAttributedTimeString(timeString)
            button.image = nil
            currentTimeString = timeString
        } else {
            if let firstTimer = activeTimers.first {
                let timeString = formatTimeForMenuBar(firstTimer.remainingTime)
                let displayString = "\(timeString) | \(activeCount)"
                button.attributedTitle = createAttributedTimeString(displayString)
                button.image = nil
                currentTimeString = timeString
            } else {
                button.title = " \(activeCount)"
                button.image = nil
            }
        }
    }
    
    /// 菜单栏专用时间格式化，使用紧凑格式
    private func formatTimeForMenuBar(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            // 超过1小时使用紧凑格式：1:23:45
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            // 1小时内使用标准格式：23:45
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func createAttributedTimeString(_ timeString: String) -> NSAttributedString {
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]

        let attachment = NSTextAttachment()
        let iconConfig = NSImage.SymbolConfiguration(pointSize: NSFont.systemFontSize, weight: .medium)
        if let timerImage = NSImage(systemSymbolName: "timer", accessibilityDescription: "计时")?.withSymbolConfiguration(iconConfig) {
            attachment.image = timerImage
        }

        let attachmentString = NSAttributedString(attachment: attachment)
        let mutableString = NSMutableAttributedString()
        mutableString.append(attachmentString)
        mutableString.append(NSAttributedString(string: " \(timeString)", attributes: attributes))

        return mutableString
    }

    @objc private func handleClick() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
            isMenuOpen = false
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isMenuOpen = true
        }
    }

    func closeMenu() {
        popover?.performClose(nil)
        isMenuOpen = false
    }

    func showMainWindow() {
        closeMenu()
        shouldShowMainWindow = true
    }

    private func performShowMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.bringWindowToFront()
        }
    }

    private func bringWindowToFront() {
        if let cachedWindow = mainWindow, cachedWindow.isVisible {
            cachedWindow.makeKeyAndOrderFront(nil)
            cachedWindow.orderFrontRegardless()
            return
        }

        for window in NSApp.windows {
            if isPopoverWindow(window) {
                continue
            }

            if window.frame.width < 400 || window.frame.height < 300 {
                continue
            }

            if window.styleMask.contains(.borderless) {
                continue
            }

            mainWindow = window
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        if let mainWindow = NSApp.mainWindow {
            self.mainWindow = mainWindow
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.orderFrontRegardless()
            return
        }

        Self.logger.warning("Could not find main window, creating new one")
        showNewMainWindow()
    }

    private func isPopoverWindow(_ window: NSWindow) -> Bool {
        if window.frame.width <= 320 && window.frame.height <= 420 {
            if window.level == .floating {
                return true
            }
        }
        return false
    }

    private func showNewMainWindow() {
        let contentView = ContentView()
            .environmentObject(timerManager!)
            .environmentObject(HotKeyManager.shared)
            .environmentObject(MenuBarManager.shared)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "倒计时提醒"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        mainWindow = window
    }

    func registerMainWindow(_ window: NSWindow) {
        mainWindow = window
    }
}
