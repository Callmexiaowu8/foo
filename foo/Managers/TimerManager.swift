import Foundation
import Combine
import UserNotifications
import SwiftUI

/// 时间同步管理器
/// 负责管理所有计时器的状态同步，确保菜单栏和主应用时间显示一致
@available(macOS 14.0, *)
@MainActor
class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    // MARK: - Published Properties
    /// 所有计时器列表
    @Published var timers: [CountdownTimer] = []
    /// 活跃计时器列表（已改为 @Published 确保视图更新）
    @Published var activeTimers: [CountdownTimer] = []
    /// 全屏提醒显示状态
    @Published var isFullscreenAlertPresented = false
    /// 已完成的计时器
    @Published var completedTimer: CountdownTimer?
    /// 最后更新时间戳（用于强制刷新）
    @Published var lastUpdateTimestamp: Date = Date()
    
    // MARK: - Private Properties
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let timersKey = "savedTimers_v2"
    /// 同步队列，用于处理并发更新
    private let syncQueue = DispatchQueue(label: "com.foo.timerSync", qos: .userInteractive)
    
    // MARK: - Initialization
    init() {
        loadTimers()
        setupNotifications()
        startGlobalTimer()
        setupActiveTimersObserver()
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    // MARK: - Active Timers Observer
    /// 设置活跃计时器观察者
    /// 监听 timers 数组变化和定时刷新，确保 activeTimers 始终同步
    private func setupActiveTimersObserver() {
        // 监听 timers 数组变化
        $timers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateActiveTimers()
            }
            .store(in: &cancellables)
        
        // 高频刷新（每100ms）确保时间显示流畅
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTimeDisplay()
            }
            .store(in: &cancellables)
    }
    
    /// 刷新时间显示（不重建数组，只触发更新）
    private func refreshTimeDisplay() {
        // 更新最后更新时间戳，强制 SwiftUI 刷新
        lastUpdateTimestamp = Date()
        
        // 检查是否有计时器需要更新 activeTimers 状态
        let currentActiveIds = Set(activeTimers.map { $0.id })
        let shouldBeActive = timers.filter { $0.isActive || $0.isPaused }
        let shouldBeActiveIds = Set(shouldBeActive.map { $0.id })
        
        // 如果活跃计时器集合发生变化，更新 activeTimers
        if currentActiveIds != shouldBeActiveIds {
            activeTimers = shouldBeActive
        }
    }
    
    /// 更新活跃计时器列表
    private func updateActiveTimers() {
        let newActiveTimers = timers.filter { $0.isActive || $0.isPaused }
        
        // 检查内容是否真正变化（ID集合 + 状态）
        let currentIds = Set(activeTimers.map { $0.id })
        let newIds = Set(newActiveTimers.map { $0.id })
        
        let currentStates = Dictionary(uniqueKeysWithValues: activeTimers.map { ($0.id, $0.isActive) })
        let newStates = Dictionary(uniqueKeysWithValues: newActiveTimers.map { ($0.id, $0.isActive) })
        
        if currentIds != newIds || currentStates != newStates {
            activeTimers = newActiveTimers
            objectWillChange.send() // 强制触发更新通知
        }
    }
    
    // MARK: - Global Timer
    /// 启动全局计时器
    /// 使用单个定时器更新所有活跃计时器，确保同步
    private func startGlobalTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateAllTimers()
            }
    }
    
    /// 更新所有计时器
    /// 每秒调用一次，更新活跃计时器的剩余时间
    private func updateAllTimers() {
        var hasChanges = false
        
        for timer in timers where timer.isActive && !timer.isPaused {
            let wasCompleted = timer.tick()
            if wasCompleted {
                completeTimer(timer)
                hasChanges = true
            } else {
                hasChanges = true
            }
        }
        
        // 只要有变化就保存和更新
        if hasChanges {
            saveTimers()
            updateActiveTimers()
            lastUpdateTimestamp = Date()
        }
    }
    
    // MARK: - Timer Management
    
    func addTimer(_ timer: CountdownTimer) {
        timers.append(timer)
        updateActiveTimers()
        saveTimers()
    }
    
    func updateTimer(_ timer: CountdownTimer) {
        updateActiveTimers()
        saveTimers()
    }
    
    func deleteTimer(_ timer: CountdownTimer) {
        timer.stop()
        timers.removeAll { $0.id == timer.id }
        updateActiveTimers()
        saveTimers()
    }
    
    /// 开始计时器
    /// - Parameter timer: 要开始的计时器
    func startTimer(_ timer: CountdownTimer) {
        timer.start()
        updateActiveTimers()
        saveTimers()
        lastUpdateTimestamp = Date()
    }
    
    /// 暂停计时器
    /// - Parameter timer: 要暂停的计时器
    func pauseTimer(_ timer: CountdownTimer) {
        timer.pause()
        updateActiveTimers()
        saveTimers()
        lastUpdateTimestamp = Date()
    }
    
    /// 恢复计时器
    /// - Parameter timer: 要恢复的计时器
    func resumeTimer(_ timer: CountdownTimer) {
        timer.resume()
        updateActiveTimers()
        saveTimers()
        lastUpdateTimestamp = Date()
    }
    
    /// 停止计时器
    /// - Parameter timer: 要停止的计时器
    func stopTimer(_ timer: CountdownTimer) {
        timer.stop()
        updateActiveTimers()
        saveTimers()
        lastUpdateTimestamp = Date()
    }
    
    func resetTimer(_ timer: CountdownTimer) {
        timer.reset()
        updateActiveTimers()
        saveTimers()
    }
    
    func skipTimer(_ timer: CountdownTimer) {
        completeTimer(timer)
    }
    
    // MARK: - Completion Handling
    
    private func completeTimer(_ timer: CountdownTimer) {
        timer.stop()
        timer.remainingTime = 0
        
        self.completedTimer = timer
        
        if timer.showFullscreenAlert {
            isFullscreenAlertPresented = true
        }
        
        sendNotification(for: timer)
        handleRepeat(for: timer)
        updateActiveTimers()
        saveTimers()
        lastUpdateTimestamp = Date()
    }
    
    // MARK: - Repeat Handling
    
    private func handleRepeat(for timer: CountdownTimer) {
        guard timer.repeatFrequency != .once else { return }
        
        if let endDate = timer.endDate, Date() > endDate {
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
    }
    
    func dismissAlert() {
        isFullscreenAlertPresented = false
        completedTimer = nil
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission: \(granted)")
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
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveTimers() {
        do {
            let encoded = try JSONEncoder().encode(timers)
            userDefaults.set(encoded, forKey: timersKey)
        } catch {
            print("Failed to save timers: \(error)")
        }
    }
    
    private func loadTimers() {
        guard let data = userDefaults.data(forKey: timersKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode([CountdownTimer].self, from: data)
            timers = decoded
            updateActiveTimers()
        } catch {
            print("Failed to load timers: \(error)")
            loadLegacyTimers()
        }
    }
    
    private func loadLegacyTimers() {
        let legacyKey = "savedTimers"
        guard let data = userDefaults.data(forKey: legacyKey) else { return }
        
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
            timers = legacyTimers.map { legacy in
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
            saveTimers()
            updateActiveTimers()
        } catch {
            print("Failed to load legacy timers: \(error)")
        }
    }
    
    // MARK: - Background Handling
    
    func handleAppDidEnterBackground() {
        saveTimers()
    }
    
    func handleAppWillEnterForeground() {
        // 计算后台经过的时间并更新计时器
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
        saveTimers()
        lastUpdateTimestamp = Date()
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
    
    func getRemainingTime(for timer: CountdownTimer) -> TimeInterval {
        return timer.remainingTime
    }
    
    func isTimerActive(_ timer: CountdownTimer) -> Bool {
        return timer.isActive
    }
    
    func isTimerPaused(_ timer: CountdownTimer) -> Bool {
        return timer.isPaused
    }
}
