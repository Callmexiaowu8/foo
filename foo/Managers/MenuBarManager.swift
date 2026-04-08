import Foundation
import AppKit
import SwiftUI
import Combine
import os.log

enum MenuBarDisplayMode: String, CaseIterable {
    case staticIcon = "静态图标"
    case dynamicTimer = "动态倒计时"
    case compact = "紧凑模式"
}

@available(macOS 14.0, *)
@MainActor
final class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()

    private static let logger = Logger(subsystem: "com.foo.CountdownReminder", category: "MenuBarManager")

    @Published var displayMode: MenuBarDisplayMode = .dynamicTimer
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

        let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "倒计时提醒")
        image?.isTemplate = true
        button.image = image

        button.action = #selector(handleClick)
        button.target = self

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = false
        self.popover = popover
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
            currentTimeString = ""
        } else if activeCount == 1, let timer = activeTimers.first {
            let timeString = timerManager.formatTime(timer.remainingTime)
            button.title = " \(timeString)"
            currentTimeString = timeString
        } else {
            if let firstTimer = activeTimers.first {
                let timeString = timerManager.formatTime(firstTimer.remainingTime)
                button.title = " \(timeString) | \(activeCount)"
                currentTimeString = timeString
            } else {
                button.title = " \(activeCount)"
            }
        }
    }

    @objc private func handleClick() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
            isMenuOpen = false
        } else {
            let contentView = MenuBarPopoverView()
                .environmentObject(timerManager!)

            popover.contentViewController = NSHostingController(rootView: contentView)
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

    func setDisplayMode(_ mode: MenuBarDisplayMode) {
        displayMode = mode
        updateMenuBar()
    }

    func registerMainWindow(_ window: NSWindow) {
        mainWindow = window
    }
}
