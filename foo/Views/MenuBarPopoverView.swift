import SwiftUI

@available(macOS 14.0, *)
struct MenuBarPopoverView: View {
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            if timerManager.activeTimers.isEmpty {
                emptyStateSection
            } else {
                timersListSection
            }

            Divider()

            footerSection
        }
        .frame(width: 280)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Text("倒计时")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Button(action: createNewTimer) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 28, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.15))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help("新建倒计时")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("暂无进行中的计时器")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("点击 + 新建一个")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    private var timersListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(timerManager.activeTimers) { timer in
                    TimerCard(timer: timer)
                        .environmentObject(timerManager)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 240)
    }

    private var footerSection: some View {
        HStack {
            Text("\(timerManager.timers.count) 个计时器")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            if !timerManager.activeTimers.isEmpty {
                Button(action: toggleAllTimers) {
                    Text(allPaused ? "全部继续" : "全部暂停")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help(allPaused ? "继续所有计时器" : "暂停所有计时器")

                Text("·")
                    .foregroundColor(.secondary)

                Button(action: stopAllTimers) {
                    Text("取消全部")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("取消所有计时器")

                Text("·")
                    .foregroundColor(.secondary)
            }

            Button(action: openMainWindow) {
                Text("详情")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("打开主窗口")

            Text("·")
                .foregroundColor(.secondary)

            Button(action: { NSApp.terminate(nil) }) {
                Text("退出")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var allPaused: Bool {
        timerManager.activeTimers.allSatisfy { $0.isPaused }
    }

    private func toggleAllTimers() {
        for timer in timerManager.activeTimers {
            if allPaused {
                if timer.isPaused {
                    timerManager.resumeTimer(timer)
                }
            } else {
                if timer.isActive {
                    timerManager.pauseTimer(timer)
                }
            }
        }
    }

    private func stopAllTimers() {
        for timer in timerManager.activeTimers {
            timerManager.stopTimer(timer)
        }
    }

    private func createNewTimer() {
        MenuBarManager.shared.closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: AppNotifications.showAddTimerSheet, object: nil)
            MenuBarManager.shared.showMainWindow()
        }
    }

    private func openMainWindow() {
        MenuBarManager.shared.showMainWindow()
    }
}

@available(macOS 14.0, *)
struct TimerCard: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var timer: CountdownTimer
    @State private var isHovering = false

    private var formattedTime: String {
        timerManager.formatTime(timer.remainingTime)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(timer.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formattedTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(timer.isPaused ? .orange : .secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                if timer.isActive {
                    controlButton(icon: "pause.fill", color: .orange, tooltip: "暂停") {
                        timerManager.pauseTimer(timer)
                    }
                } else if timer.isPaused {
                    controlButton(icon: "play.fill", color: .green, tooltip: "继续") {
                        timerManager.resumeTimer(timer)
                    }
                } else {
                    controlButton(icon: "play.fill", color: .green, tooltip: "开始") {
                        timerManager.startTimer(timer)
                    }
                }

                controlButton(icon: "arrow.counterclockwise", color: .gray, tooltip: "重置") {
                    timerManager.resetTimer(timer)
                }

                controlButton(icon: "xmark", color: .red, tooltip: "取消") {
                    timerManager.stopTimer(timer)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.secondary.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var statusColor: Color {
        if timer.isActive {
            return .green
        } else if timer.isPaused {
            return .orange
        }
        return .gray
    }

    private func controlButton(icon: String, color: Color, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHovering ? color : .secondary)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovering ? color.opacity(0.12) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
}
