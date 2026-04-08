import Foundation
import Combine
import UserNotifications
import SwiftUI
import os.log

// MARK: - Timer Managing Protocol

/// 计时器管理协议
///
/// 定义计时器管理的基本操作，
/// 遵循单一职责原则和依赖倒置原则
@available(macOS 14.0, *)
protocol TimerManaging: AnyObject {
    var activeTimers: [CountdownTimer] { get }
    var timers: [CountdownTimer] { get }
    var isFullscreenAlertPresented: Bool { get }
    var completedTimer: CountdownTimer? { get }

    func addTimer(_ timer: CountdownTimer)
    func updateTimer(_ timer: CountdownTimer)
    func deleteTimer(_ timer: CountdownTimer)
    func startTimer(_ timer: CountdownTimer)
    func pauseTimer(_ timer: CountdownTimer)
    func resumeTimer(_ timer: CountdownTimer)
    func stopTimer(_ timer: CountdownTimer)
    func resetTimer(_ timer: CountdownTimer)
    func skipTimer(_ timer: CountdownTimer)
    func formatTime(_ timeInterval: TimeInterval) -> String
}

// MARK: - Timer State

/// 计时器状态枚举
@available(macOS 14.0, *)
enum TimerState {
    case started, paused, resumed, stopped

    func apply(to timer: CountdownTimer) {
        switch self {
        case .started: timer.start()
        case .paused: timer.pause()
        case .resumed: timer.resume()
        case .stopped: timer.stop()
        }
    }
}

// MARK: - Timer Manager

/// 时间同步管理器
/// 负责管理所有计时器的状态同步，确保菜单栏和主应用时间显示一致
@available(macOS 14.0, *)
@MainActor
class TimerManager: ObservableObject, TimerManaging {
    static let shared = TimerManager()

    // MARK: - Constants
    private enum Constants {
        static let refreshInterval: TimeInterval = 0.1
        static let timersKey = "savedTimers_v4"
        static let maxTitleLength = 100
        static let maxDescriptionLength = 500
        static let saveDebounceInterval: TimeInterval = 2.0
    }

    // MARK: - Logging
    private static let logger = Logger(subsystem: "com.foo.CountdownReminder", category: "TimerManager")

    // MARK: - Published Properties
    @Published private(set) var timers: [CountdownTimer] = []
    @Published private(set) var activeTimers: [CountdownTimer] = []
    @Published var isFullscreenAlertPresented = false
    @Published var completedTimer: CountdownTimer?
    @Published private(set) var lastUpdateTimestamp: Date = Date()

    // MARK: - Private Properties
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private var needsRefresh = false
    private var isDirty = false
    private var saveTask: Task<Void, Never>?

    // MARK: - Initialization
    init() {
        Self.logger.info("TimerManager initialized")
        loadTimers()
        setupNotifications()
        startGlobalTimer()
        setupActiveTimersObserver()
    }

    deinit {
        timerCancellable?.cancel()
        saveTask?.cancel()
    }

    // MARK: - Active Timers Observer
    private func setupActiveTimersObserver() {
        $timers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateActiveTimers()
            }
            .store(in: &cancellables)

        Timer.publish(every: Constants.refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTimeDisplayIfNeeded()
            }
            .store(in: &cancellables)
    }

    private func refreshTimeDisplayIfNeeded() {
        guard needsRefresh else { return }
        lastUpdateTimestamp = Date()
        needsRefresh = false
    }

    private func updateActiveTimers() {
        let newActiveTimers = timers.filter { $0.isActive || $0.isPaused }
        let currentIds = Set(activeTimers.map { $0.id })
        let newIds = Set(newActiveTimers.map { $0.id })

        guard currentIds != newIds else { return }

        activeTimers = newActiveTimers
        objectWillChange.send()
        needsRefresh = true
        markDirty()
        Self.logger.debug("Active timers updated: \(self.activeTimers.count)")
    }

    // MARK: - Global Timer
    private func startGlobalTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateAllTimers()
            }
    }

    private func updateAllTimers() {
        var hasChanges = false

        for timer in timers where timer.isActive && !timer.isPaused {
            timer.tick()
            if timer.remainingTime <= 0 {
                completeTimer(timer)
            }
            hasChanges = true
            Self.logger.debug("Timer ticked: \(timer.title), remaining: \(timer.remainingTime)")
        }

        if hasChanges {
            updateActiveTimers()
            markDirty()
        }
    }

    // MARK: - Dirty Flag & Batch Save
    private func markDirty() {
        isDirty = true
        scheduleDelayedSave()
    }

    private func scheduleDelayedSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Constants.saveDebounceInterval * 1_000_000_000))
            guard notCancelled else { return }
            self.saveIfDirty()
        }
    }

    private var notCancelled: Bool {
        !Task.isCancelled
    }

    private func saveIfDirty() {
        guard isDirty else { return }
        saveTimers()
        isDirty = false
        Self.logger.debug("Timers saved (batch)")
    }

    // MARK: - Timer Management
    func addTimer(_ timer: CountdownTimer) {
        let validatedTimer = validateAndCloneTimer(timer)
        timers.append(validatedTimer)
        updateActiveTimers()
        markDirty()
        Self.logger.info("Timer added: \(validatedTimer.title)")
    }

    func updateTimer(_ timer: CountdownTimer) {
        updateActiveTimers()
        markDirty()
    }

    func deleteTimer(_ timer: CountdownTimer) {
        timer.stop()
        timers.removeAll { $0.id == timer.id }
        updateActiveTimers()
        markDirty()
        Self.logger.info("Timer deleted: \(timer.title)")
    }

    func startTimer(_ timer: CountdownTimer) {
        performStateChange(timer, state: .started)
    }

    func pauseTimer(_ timer: CountdownTimer) {
        performStateChange(timer, state: .paused)
    }

    func resumeTimer(_ timer: CountdownTimer) {
        performStateChange(timer, state: .resumed)
    }

    func stopTimer(_ timer: CountdownTimer) {
        performStateChange(timer, state: .stopped)
    }

    func resetTimer(_ timer: CountdownTimer) {
        timer.reset()
        updateActiveTimers()
        markDirty()
    }

    func skipTimer(_ timer: CountdownTimer) {
        completeTimer(timer)
    }

    // MARK: - State Change
    private func performStateChange(_ timer: CountdownTimer, state: TimerState) {
        state.apply(to: timer)
        updateActiveTimers()
        markDirty()
        Self.logger.debug("Timer state changed: \(timer.title) -> \(String(describing: state))")
    }

    // MARK: - Completion Handling
    private func completeTimer(_ timer: CountdownTimer) {
        guard timer.remainingTime <= 0 else { return }

        timer.stop()
        completedTimer = timer

        if timer.showFullscreenAlert {
            isFullscreenAlertPresented = true
            Self.logger.info("Fullscreen alert shown for: \(timer.title)")
        }

        sendNotification(for: timer)
        handleRepeat(for: timer)
        updateActiveTimers()
        markDirty()
    }

    // MARK: - Repeat Handling
    private func handleRepeat(for timer: CountdownTimer) {
        guard timer.repeatFrequency != .once else { return }

        if let endDate = timer.endDate, Date() > endDate {
            Self.logger.info("Timer repeat ended (past end date): \(timer.title)")
            return
        }

        let nextTimer = CountdownTimer(
            title: timer.title,
            description: timer.timerDescription,
            duration: timer.duration,
            repeatFrequency: timer.repeatFrequency,
            endDate: timer.endDate,
            soundEnabled: timer.soundEnabled,
            showFullscreenAlert: timer.showFullscreenAlert
        )

        addTimer(nextTimer)
    }

    // MARK: - Snooze
    func snoozeTimer(minutes: Int) {
        guard let completedTimer = completedTimer else { return }

        isFullscreenAlertPresented = false

        let snoozeTimer = CountdownTimer(
            title: "\(completedTimer.title) (延迟)",
            description: completedTimer.timerDescription,
            duration: TimeInterval(minutes * 60),
            soundEnabled: completedTimer.soundEnabled,
            showFullscreenAlert: completedTimer.showFullscreenAlert
        )

        addTimer(snoozeTimer)
        startTimer(snoozeTimer)
        Self.logger.info("Timer snoozed for \(minutes) minutes: \(completedTimer.title)")
    }

    func dismissAlert() {
        isFullscreenAlertPresented = false
        completedTimer = nil
    }

    // MARK: - Notifications
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                Self.logger.error("Notification permission error: \(error.localizedDescription)")
            } else {
                Self.logger.info("Notification permission granted: \(granted)")
            }
        }
    }

    private func sendNotification(for timer: CountdownTimer) {
        let content = UNMutableNotificationContent()
        content.title = timer.title
        content.body = timer.timerDescription.isEmpty ? "倒计时结束！" : timer.timerDescription
        content.sound = timer.soundEnabled ? .default : nil
        content.badge = 1

        let request = UNNotificationRequest(
            identifier: timer.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                Self.logger.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Data Persistence
    private func saveTimers() {
        do {
            let encoded = try JSONEncoder().encode(timers)
            userDefaults.set(encoded, forKey: Constants.timersKey)
        } catch {
            Self.logger.error("Failed to save timers: \(error.localizedDescription)")
        }
    }

    private func loadTimers() {
        guard let data = userDefaults.data(forKey: Constants.timersKey) else {
            Self.logger.info("No saved timers found")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([CountdownTimer].self, from: data)
            timers = decoded
            updateActiveTimers()
            Self.logger.info("Loaded \(decoded.count) timers")
        } catch {
            Self.logger.error("Failed to load timers: \(error.localizedDescription)")
            loadLegacyTimers()
        }
    }

    // MARK: - Legacy Data Migration
    private func loadLegacyTimers() {
        let legacyKeys = ["savedTimers_v3", "savedTimers_v2", "savedTimers"]

        for key in legacyKeys {
            guard let data = userDefaults.data(forKey: key) else { continue }

            do {
                struct LegacyTimer: Codable {
                    let id: UUID
                    let title: String
                    let description: String
                    let duration: TimeInterval
                    let remainingTime: TimeInterval
                    let isActive: Bool
                    let isPaused: Bool
                    let repeatFrequency: RepeatFrequency
                    let endDate: Date?
                    let createdAt: Date
                    let lastStartedAt: Date?
                    let soundEnabled: Bool
                    let showFullscreenAlert: Bool
                }

                let legacyTimers = try JSONDecoder().decode([LegacyTimer].self, from: data)
                self.timers = legacyTimers.map { legacy in
                    let timer = CountdownTimer(
                        id: legacy.id,
                        title: legacy.title,
                        description: legacy.description,
                        duration: legacy.duration,
                        repeatFrequency: legacy.repeatFrequency,
                        endDate: legacy.endDate,
                        soundEnabled: legacy.soundEnabled,
                        showFullscreenAlert: legacy.showFullscreenAlert
                    )
                    timer.remainingTime = legacy.remainingTime
                    timer.isActive = false
                    timer.isPaused = false
                    timer.lastStartedAt = legacy.lastStartedAt
                    return timer
                }
                markDirty()
                Self.logger.info("Legacy timers migrated from \(key): \(self.timers.count) timers")
                return
            } catch {
                Self.logger.warning("Failed to migrate legacy timers from \(key): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Background Handling
    nonisolated func handleAppDidEnterBackground() {
        Task { @MainActor in
            saveIfDirty()
        }
    }

    nonisolated func handleAppWillEnterForeground() {
        Task { @MainActor in
            for timer in timers where timer.isActive && !timer.isPaused {
                guard let lastStartedAt = timer.lastStartedAt else { continue }

                let timeSinceLastUpdate = Date().timeIntervalSince(lastStartedAt)
                let secondsToSubtract = Int(timeSinceLastUpdate)

                if secondsToSubtract > 0 {
                    timer.remainingTime = max(0, timer.remainingTime - TimeInterval(secondsToSubtract))
                    timer.lastStartedAt = Date()

                    if timer.remainingTime <= 0 {
                        completeTimer(timer)
                    }
                }
            }
            updateActiveTimers()
            markDirty()
        }
    }

    // MARK: - Input Validation
    private func validateAndCloneTimer(_ timer: CountdownTimer) -> CountdownTimer {
        let validatedTitle = String(timer.title.prefix(Constants.maxTitleLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        let validatedDescription = String(timer.timerDescription.prefix(Constants.maxDescriptionLength)).trimmingCharacters(in: .whitespacesAndNewlines)

        if validatedTitle != timer.title || validatedDescription != timer.timerDescription {
            Self.logger.warning("Timer input was sanitized: title=\(validatedTitle), description=\(validatedDescription)")
        }

        let cloned = CountdownTimer(
            id: timer.id,
            title: validatedTitle.isEmpty ? "未命名计时器" : validatedTitle,
            description: validatedDescription,
            duration: timer.duration,
            repeatFrequency: timer.repeatFrequency,
            endDate: timer.endDate,
            soundEnabled: timer.soundEnabled,
            showFullscreenAlert: timer.showFullscreenAlert
        )
        cloned.remainingTime = timer.remainingTime
        cloned.isActive = timer.isActive
        cloned.isPaused = timer.isPaused
        cloned.lastStartedAt = timer.lastStartedAt

        return cloned
    }

    // MARK: - Formatting
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
