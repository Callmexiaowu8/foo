import XCTest
@testable import foo
import Combine

/// 时间同步单元测试
/// 测试菜单栏与主应用时间同步的正确性
@available(macOS 14.0, *)
class TimerSyncTests: XCTestCase {

    var timerManager: TimerManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        timerManager = nil
        super.tearDown()
    }

    // MARK: - 时间同步测试

    /// 测试：开始计时器后 activeTimers 是否正确更新
    func testStartTimerUpdatesActiveTimers() {
        let timer = CountdownTimer(
            title: "测试计时器",
            duration: 60
        )
        timerManager.addTimer(timer)

        XCTAssertEqual(timerManager.activeTimers.count, 0)

        timerManager.startTimer(timer)

        XCTAssertEqual(timerManager.activeTimers.count, 1)
        XCTAssertEqual(timerManager.activeTimers.first?.id, timer.id)
        XCTAssertTrue(timerManager.activeTimers.first?.isActive ?? false)
    }

    /// 测试：暂停计时器后状态同步
    func testPauseTimerSync() {
        let timer = CountdownTimer(
            title: "测试计时器",
            duration: 60
        )
        timerManager.addTimer(timer)
        timerManager.startTimer(timer)

        XCTAssertTrue(timer.isActive)
        XCTAssertFalse(timer.isPaused)

        timerManager.pauseTimer(timer)

        XCTAssertFalse(timer.isActive)
        XCTAssertTrue(timer.isPaused)
        XCTAssertEqual(timerManager.activeTimers.count, 1)
        XCTAssertTrue(timerManager.activeTimers.first?.isPaused ?? false)
    }

    /// 测试：停止计时器后从 activeTimers 移除
    func testStopTimerRemovesFromActive() {
        let timer = CountdownTimer(
            title: "测试计时器",
            duration: 60
        )
        timerManager.addTimer(timer)
        timerManager.startTimer(timer)

        XCTAssertEqual(timerManager.activeTimers.count, 1)

        timerManager.stopTimer(timer)

        XCTAssertEqual(timerManager.activeTimers.count, 0)
        XCTAssertFalse(timer.isActive)
        XCTAssertFalse(timer.isPaused)
    }

    /// 测试：多个计时器的 activeTimers 管理
    func testMultipleTimersActiveManagement() {
        let timer1 = CountdownTimer(title: "计时器1", duration: 60)
        let timer2 = CountdownTimer(title: "计时器2", duration: 120)
        let timer3 = CountdownTimer(title: "计时器3", duration: 180)

        timerManager.addTimer(timer1)
        timerManager.addTimer(timer2)
        timerManager.addTimer(timer3)

        timerManager.startTimer(timer1)
        timerManager.startTimer(timer2)

        XCTAssertEqual(timerManager.activeTimers.count, 2)

        timerManager.stopTimer(timer1)

        XCTAssertEqual(timerManager.activeTimers.count, 1)
        XCTAssertEqual(timerManager.activeTimers.first?.id, timer2.id)
    }

    // MARK: - 时间更新测试

    /// 测试：时间戳更新机制
    func testTimestampUpdate() {
        let expectation = self.expectation(description: "时间戳更新")
        var timestampUpdated = false

        timerManager.$lastUpdateTimestamp
            .dropFirst()
            .sink { _ in
                timestampUpdated = true
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let timer = CountdownTimer(title: "测试", duration: 60)
        timerManager.addTimer(timer)
        timerManager.startTimer(timer)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(timestampUpdated)
    }

    /// 测试：时间格式化一致性
    func testTimeFormattingConsistency() {
        let testCases: [(TimeInterval, String)] = [
            (60, "01:00"),
            (90, "01:30"),
            (3600, "01:00:00"),
            (3661, "01:01:01"),
            (0, "00:00"),
            (-10, "00:00")
        ]

        for (input, expected) in testCases {
            let result = timerManager.formatTime(input)
            XCTAssertEqual(result, expected, "格式化 \(input) 秒应该返回 \(expected)，但得到 \(result)")
        }
    }

    // MARK: - 状态同步测试

    /// 测试：activeTimers 与 timers 状态一致性
    func testActiveTimersConsistency() {
        let timer = CountdownTimer(title: "测试", duration: 60)
        timerManager.addTimer(timer)

        timerManager.startTimer(timer)

        let activeFromTimers = timerManager.timers.filter { $0.isActive || $0.isPaused }
        XCTAssertEqual(timerManager.activeTimers.count, activeFromTimers.count)

        for activeTimer in timerManager.activeTimers {
            let originalTimer = timerManager.timers.first { $0.id == activeTimer.id }
            XCTAssertNotNil(originalTimer)
            XCTAssertEqual(originalTimer?.isActive, activeTimer.isActive)
            XCTAssertEqual(originalTimer?.isPaused, activeTimer.isPaused)
            XCTAssertEqual(originalTimer?.remainingTime, activeTimer.remainingTime)
        }
    }

    /// 测试：计时器 tick 后状态更新
    func testTimerTickUpdatesState() {
        let timer = CountdownTimer(title: "测试", duration: 5)
        timerManager.addTimer(timer)
        timerManager.startTimer(timer)

        let initialRemaining = timer.remainingTime

        let completed = timer.tick()

        XCTAssertFalse(completed)
        XCTAssertEqual(timer.remainingTime, initialRemaining - 1)
    }

    /// 测试：计时器完成后的处理
    func testTimerCompletion() {
        let timer = CountdownTimer(title: "测试", duration: 1)
        timerManager.addTimer(timer)
        timerManager.startTimer(timer)

        timer.remainingTime = 1

        let completed = timer.tick()

        XCTAssertTrue(completed)
        XCTAssertEqual(timer.remainingTime, 0)
    }

    // MARK: - 性能测试

    /// 测试：状态更新性能（延迟应小于 100ms）
    func testStateUpdatePerformance() {
        let timer = CountdownTimer(title: "性能测试", duration: 3600)
        timerManager.addTimer(timer)

        measure {
            for _ in 0..<100 {
                timerManager.startTimer(timer)
                timerManager.pauseTimer(timer)
                timerManager.resumeTimer(timer)
                timerManager.stopTimer(timer)
            }
        }
    }

    /// 测试：大量计时器的 activeTimers 更新性能
    func testLargeNumberOfTimersPerformance() {
        for i in 0..<100 {
            let timer = CountdownTimer(title: "计时器 \(i)", duration: TimeInterval(60 + i))
            timerManager.addTimer(timer)
            if i % 2 == 0 {
                timerManager.startTimer(timer)
            }
        }

        XCTAssertEqual(timerManager.activeTimers.count, 50)

        measure {
            for timer in timerManager.activeTimers {
                timerManager.stopTimer(timer)
            }
        }

        XCTAssertEqual(timerManager.activeTimers.count, 0)
    }

    // MARK: - 输入验证测试

    /// 测试：计时器标题长度验证
    func testTimerTitleLengthValidation() {
        let longTitle = String(repeating: "a", count: 150)
        let timer = CountdownTimer(title: longTitle, duration: 60)
        timerManager.addTimer(timer)

        let savedTimer = timerManager.timers.first { $0.id == timer.id }
        XCTAssertEqual(savedTimer?.title.count, 100)
    }

    /// 测试：空标题默认为"未命名计时器"
    func testEmptyTitleDefaultsToUnnamed() {
        let timer = CountdownTimer(title: "   ", duration: 60)
        timerManager.addTimer(timer)

        let savedTimer = timerManager.timers.first { $0.id == timer.id }
        XCTAssertEqual(savedTimer?.title, "未命名计时器")
    }
}
