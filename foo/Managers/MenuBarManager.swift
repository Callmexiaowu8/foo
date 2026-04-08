import Foundation
import AppKit
import SwiftUI
import Combine

/// 菜单栏显示模式
enum MenuBarDisplayMode: String, CaseIterable {
    case staticIcon = "静态图标"
    case dynamicTimer = "动态倒计时"
    case compact = "紧凑模式"
}

/// 菜单栏管理器 - 负责管理菜单栏的显示和交互
/// 确保菜单栏时间与主应用完全同步
@available(macOS 14.0, *)
@MainActor
final class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()

    // MARK: - Published Properties
    @Published var displayMode: MenuBarDisplayMode = .dynamicTimer
    @Published var isMenuOpen = false
    @Published var currentTimeString: String = ""
    @Published var shouldShowMainWindow = false

    // MARK: - Private Properties
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var timerManager: TimerManager?
    private var cancellables = Set<AnyCancellable>()
    private var isConfigured = false
    private var mainWindow: NSWindow?
    private var mainWindowController: NSWindowController?

    // MARK: - Initialization
    private override init() {
        super.init()
    }

    // MARK: - Setup
    func configure(with timerManager: TimerManager) {
        guard !isConfigured else {
            print("菜单栏已经配置，跳过重复初始化")
            return
        }

        isConfigured = true
        self.timerManager = timerManager
        setupMenuBar()
        setupObservers()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            print("无法创建状态栏按钮")
            return
        }

        print("菜单栏已设置完成")

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

    // MARK: - Update
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

    // MARK: - Actions
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
        // 策略1：如果有缓存的主窗口且有效，使用它
        if let cachedWindow = mainWindow, cachedWindow.isVisible {
            print("使用缓存的主窗口")
            cachedWindow.makeKeyAndOrderFront(nil)
            cachedWindow.orderFrontRegardless()
            return
        }

        // 策略2：查找符合主窗口特征的窗口
        // 主窗口特征：不是popover，尺寸较大，有标题栏
        for window in NSApp.windows {
            // 跳过 popover 窗口（通常是小型浮动窗口）
            if isPopoverWindow(window) {
                continue
            }

            // 跳过尺寸太小的窗口（不是主窗口）
            if window.frame.width < 400 || window.frame.height < 300 {
                continue
            }

            // 跳过没有标题栏的窗口
            if window.styleMask.contains(.borderless) {
                continue
            }

            // 这是一个候选主窗口
            print("找到候选主窗口: \(window.title), frame: \(window.frame), class: \(window.className)")
            mainWindow = window
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        // 策略3：如果实在找不到，尝试使用 NSApp.mainWindow
        if let mainWindow = NSApp.mainWindow {
            self.mainWindow = mainWindow
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.orderFrontRegardless()
            return
        }

        // 策略4：尝试显示新窗口
        print("警告：无法找到主窗口，尝试创建新窗口")
        showNewMainWindow()
    }

    private func isPopoverWindow(_ window: NSWindow) -> Bool {
        // Popover 窗口的特征
        // Popover 通常是小尺寸浮动窗口
        if window.frame.width <= 320 && window.frame.height <= 420 {
            if window.level == .floating {
                return true
            }
        }
        return false
    }

    private func showNewMainWindow() {
        // 创建新的主窗口
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
        print("主窗口已注册: \(window.title), frame: \(window.frame)")
    }
}
