import SwiftUI
import UserNotifications
import Combine

@available(macOS 14.0, *)
struct AppNotifications {
    static let showAddTimerSheet = Foundation.Notification.Name("showAddTimerSheet")
}

@main
@available(macOS 14.0, *)
struct CountdownReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let timerManager = TimerManager.shared
    private let hotKeyManager = HotKeyManager.shared

    init() {
        MenuBarManager.shared.configure(with: TimerManager.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .environmentObject(hotKeyManager)
                .environmentObject(MenuBarManager.shared)
                .frame(minWidth: 450, minHeight: 500)
                .onAppear {
                    setupHotKeys()
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 500, height: 650)
    }

    private func setupHotKeys() {
        hotKeyManager.registerQuickAddTimerHotKey {
            NotificationCenter.default.post(name: AppNotifications.showAddTimerSheet, object: nil)
        }

        hotKeyManager.registerPauseResumeHotKey { [weak timerManager] in
            guard let timerManager = timerManager else { return }
            if let firstActive = timerManager.activeTimers.first(where: { $0.isActive }) {
                timerManager.pauseTimer(firstActive)
            } else if let firstPaused = timerManager.activeTimers.first(where: { $0.isPaused }) {
                timerManager.resumeTimer(firstPaused)
            }
        }

        hotKeyManager.registerStopHotKey { [weak timerManager] in
            guard let timerManager = timerManager else { return }
            if let firstActive = timerManager.activeTimers.first {
                timerManager.stopTimer(firstActive)
            }
        }

        hotKeyManager.registerShowWindowHotKey {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

@available(macOS 14.0, *)
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        requestNotificationPermissions()
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func applicationWillTerminate(_ notification: Foundation.Notification) {
        MenuBarManager.shared.closeMenu()
    }
}
