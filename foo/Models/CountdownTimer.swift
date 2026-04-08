import Foundation
import Combine

enum RepeatFrequency: String, Codable, CaseIterable {
    case once = "单次"
    case daily = "每日"
    case weekly = "每周"
    case weekdays = "工作日"
    case weekends = "周末"

    var description: String {
        return self.rawValue
    }
}

// MARK: - Observable Timer Class
// 使用类而不是结构体，这样状态变化可以自动通知 SwiftUI
@available(macOS 14.0, *)
@MainActor
class CountdownTimer: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date

    @Published var title: String
    @Published var timerDescription: String
    @Published var duration: TimeInterval
    @Published var remainingTime: TimeInterval
    @Published var isActive: Bool
    @Published var isPaused: Bool
    @Published var repeatFrequency: RepeatFrequency
    @Published var endDate: Date?
    @Published var lastStartedAt: Date?
    @Published var soundEnabled: Bool
    @Published var showFullscreenAlert: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        duration: TimeInterval,
        repeatFrequency: RepeatFrequency = .once,
        endDate: Date? = nil,
        soundEnabled: Bool = true,
        showFullscreenAlert: Bool = true
    ) {
        self.id = id
        self.title = title
        self.timerDescription = description
        self.duration = duration
        self.remainingTime = duration
        self.isActive = false
        self.isPaused = false
        self.repeatFrequency = repeatFrequency
        self.endDate = endDate
        self.createdAt = Date()
        self.lastStartedAt = nil
        self.soundEnabled = soundEnabled
        self.showFullscreenAlert = showFullscreenAlert
    }

    // MARK: - Codable Implementation
    // 手动实现 Codable 因为 @Published 属性需要特殊处理

    enum CodingKeys: String, CodingKey {
        case id, title, timerDescription, duration, remainingTime
        case isActive, isPaused, repeatFrequency, endDate
        case createdAt, lastStartedAt, soundEnabled, showFullscreenAlert
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        timerDescription = try container.decode(String.self, forKey: .timerDescription)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        remainingTime = try container.decode(TimeInterval.self, forKey: .remainingTime)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        repeatFrequency = try container.decode(RepeatFrequency.self, forKey: .repeatFrequency)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastStartedAt = try container.decodeIfPresent(Date.self, forKey: .lastStartedAt)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        showFullscreenAlert = try container.decode(Bool.self, forKey: .showFullscreenAlert)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(timerDescription, forKey: .timerDescription)
        try container.encode(duration, forKey: .duration)
        try container.encode(remainingTime, forKey: .remainingTime)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encode(repeatFrequency, forKey: .repeatFrequency)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastStartedAt, forKey: .lastStartedAt)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(showFullscreenAlert, forKey: .showFullscreenAlert)
    }

    // MARK: - Equatable

    static func == (lhs: CountdownTimer, rhs: CountdownTimer) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var totalMinutes: Int {
        return Int(duration / 60)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else {
            return String(format: "%d分钟", minutes)
        }
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return 1.0 - (remainingTime / duration)
    }

    // MARK: - Timer Control Methods

    func start() {
        isActive = true
        isPaused = false
        lastStartedAt = Date()
        if remainingTime <= 0 {
            remainingTime = duration
        }
    }

    func pause() {
        isActive = false
        isPaused = true
    }

    func resume() {
        isActive = true
        isPaused = false
        lastStartedAt = Date()
    }

    func stop() {
        isActive = false
        isPaused = false
    }

    func reset() {
        isActive = false
        isPaused = false
        remainingTime = duration
        lastStartedAt = nil
    }

    func tick() -> Bool {
        guard isActive && !isPaused else { return false }
        remainingTime -= 1
        return remainingTime <= 0
    }
}

// MARK: - Sample Data

@available(macOS 14.0, *)
extension CountdownTimer {
    static var sampleTimers: [CountdownTimer] {
        [
            CountdownTimer(
                title: "喝水",
                description: "该喝水了，保持身体水分充足",
                duration: 3600,
                repeatFrequency: .daily
            ),
            CountdownTimer(
                title: "休息",
                description: "站起来活动一下，保护眼睛和颈椎",
                duration: 2700,
                repeatFrequency: .weekdays
            ),
            CountdownTimer(
                title: "专注工作",
                description: "专注时间结束，休息一下",
                duration: 1500,
                repeatFrequency: .once
            )
        ]
    }
}
