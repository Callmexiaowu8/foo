import Foundation
import Combine

enum RepeatFrequency: String, Codable, CaseIterable {
    case once = "单次"
    case daily = "每日"
    case weekly = "每周"
    case weekdays = "工作日"
    case weekends = "周末"

    var description: String {
        switch self {
        case .once: return "单次"
        case .daily: return "每日"
        case .weekly: return "每周"
        case .weekdays: return "工作日"
        case .weekends: return "周末"
        }
    }

    var iconName: String {
        switch self {
        case .once: return "1.circle"
        case .daily: return "sunrise"
        case .weekly: return "calendar"
        case .weekdays: return "briefcase"
        case .weekends: return "bed.double"
        }
    }

    static var selectableCases: [RepeatFrequency] {
        return allCases.filter { $0 != .once }
    }
}

enum ReminderType: String, Codable {
    case fullscreen = "全屏幕"
    case banner = "侧边栏通知"

    var description: String {
        switch self {
        case .fullscreen: return "全屏幕提醒"
        case .banner: return "侧边栏通知"
        }
    }

    var iconName: String {
        switch self {
        case .fullscreen: return "macwindow"
        case .banner: return "bell.badge"
        }
    }

    static var allCases: [ReminderType] {
        [.fullscreen, .banner]
    }
}

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
    @Published var reminderType: ReminderType
    @Published var reminderStartHour: Int
    @Published var reminderStartMinute: Int
    @Published var reminderEndHour: Int
    @Published var reminderEndMinute: Int
    @Published var hasTimeRange: Bool
    @Published var autoDismissSeconds: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        duration: TimeInterval,
        repeatFrequency: RepeatFrequency = .once,
        endDate: Date? = nil,
        soundEnabled: Bool = true,
        reminderType: ReminderType = .fullscreen,
        autoDismissSeconds: Int = 15
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
        self.reminderType = reminderType
        self.reminderStartHour = 0
        self.reminderStartMinute = 0
        self.reminderEndHour = 23
        self.reminderEndMinute = 59
        self.hasTimeRange = false
        self.autoDismissSeconds = autoDismissSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id, title, timerDescription, duration, remainingTime
        case isActive, isPaused, repeatFrequency, endDate
        case createdAt, lastStartedAt, soundEnabled, reminderType
        case reminderStartHour, reminderStartMinute
        case reminderEndHour, reminderEndMinute, hasTimeRange
        case autoDismissSeconds
    }

    enum OldCodingKeys: String, CodingKey {
        case id, title, timerDescription, duration, remainingTime
        case isActive, isPaused, repeatFrequency, endDate
        case createdAt, lastStartedAt, soundEnabled, showFullscreenAlert
        case reminderStartHour, reminderStartMinute
        case reminderEndHour, reminderEndMinute, hasTimeRange
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
        if let rt = try? container.decode(ReminderType.self, forKey: .reminderType) {
            reminderType = rt
        } else {
            let container2 = try decoder.container(keyedBy: OldCodingKeys.self)
            let oldFullscreen = try container2.decodeIfPresent(Bool.self, forKey: .showFullscreenAlert)
            reminderType = oldFullscreen == true ? .fullscreen : .banner
        }
        reminderStartHour = try container.decodeIfPresent(Int.self, forKey: .reminderStartHour) ?? 0
        reminderStartMinute = try container.decodeIfPresent(Int.self, forKey: .reminderStartMinute) ?? 0
        reminderEndHour = try container.decodeIfPresent(Int.self, forKey: .reminderEndHour) ?? 23
        reminderEndMinute = try container.decodeIfPresent(Int.self, forKey: .reminderEndMinute) ?? 59
        hasTimeRange = try container.decodeIfPresent(Bool.self, forKey: .hasTimeRange) ?? false
        autoDismissSeconds = try container.decodeIfPresent(Int.self, forKey: .autoDismissSeconds) ?? 15
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
        try container.encode(reminderType, forKey: .reminderType)
        try container.encode(reminderStartHour, forKey: .reminderStartHour)
        try container.encode(reminderStartMinute, forKey: .reminderStartMinute)
        try container.encode(reminderEndHour, forKey: .reminderEndHour)
        try container.encode(reminderEndMinute, forKey: .reminderEndMinute)
        try container.encode(hasTimeRange, forKey: .hasTimeRange)
        try container.encode(autoDismissSeconds, forKey: .autoDismissSeconds)
    }

    static func == (lhs: CountdownTimer, rhs: CountdownTimer) -> Bool {
        return lhs.id == rhs.id
    }

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

    var isTimeRangeValid: Bool {
        let startMinutes = reminderStartHour * 60 + reminderStartMinute
        let endMinutes = reminderEndHour * 60 + reminderEndMinute
        return startMinutes < endMinutes
    }

    var formattedTimeRange: String {
        let start = String(format: "%02d:%02d", reminderStartHour, reminderStartMinute)
        let end = String(format: "%02d:%02d", reminderEndHour, reminderEndMinute)
        return "\(start) - \(end)"
    }

    func isWithinTimeRange() -> Bool {
        guard hasTimeRange else { return true }
        guard isTimeRangeValid else { return true }
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let startMinutes = reminderStartHour * 60 + reminderStartMinute
        let endMinutes = reminderEndHour * 60 + reminderEndMinute
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }

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
