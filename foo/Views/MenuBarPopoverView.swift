import SwiftUI

@available(macOS 14.0, *)
struct MenuBarPopoverView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var hoveredTimerId: UUID?
    @State private var isHoveringNewTimer = false
    @State private var isNewTimerPressed = false
    @State private var isHoveringOpenMain = false
    @State private var isHoveringQuit = false
    @State private var showingDeleteConfirmation = false
    @State private var timerToDelete: CountdownTimer?
    @State private var showingEditTimer = false
    @State private var selectedTimer: CountdownTimer?

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .background(Color.white.opacity(0.3))

            if timerManager.activeTimers.isEmpty {
                emptyStateSection
            } else {
                timersListSection
            }

            Divider()
                .background(Color.white.opacity(0.3))

            footerSection
        }
        .frame(width: 340)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "E8F4FD"),
                    Color(hex: "F0F8FF")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showingEditTimer) {
            if let timer = selectedTimer {
                EditTimerView(timer: timer)
                    .environmentObject(timerManager)
                    .frame(width: 480, height: 720)
                    .fixedSize()
            }
        }
        .alert("删除计时器", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                timerToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let timer = timerToDelete {
                    timerManager.deleteTimer(timer)
                }
                timerToDelete = nil
            }
        } message: {
            if let timer = timerToDelete {
                Text("确定要删除「\(timer.title)」吗？此操作无法撤销。")
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0A84FF"), Color(hex: "5AC8FA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: Color(hex: "0A84FF").opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("倒计时提醒")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))

                Text("管理您的计时器")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8E8E93"))
            }

            Spacer()

            Button(action: createNewTimer) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: isHoveringNewTimer ?
                                        [Color(hex: "0077E6"), Color(hex: "4AB8EA")] :
                                        [Color(hex: "0A84FF"), Color(hex: "5AC8FA")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color(hex: "0A84FF").opacity(isHoveringNewTimer ? 0.4 : 0.3), radius: isHoveringNewTimer ? 6 : 4, x: 0, y: isHoveringNewTimer ? 3 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(isHoveringNewTimer ? 0.35 : 0.2), lineWidth: 1)
                    )
                    .scaleEffect(isHoveringNewTimer ? 1.08 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .help("新建倒计时")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringNewTimer = hovering
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                Image(systemName: "timer")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "0A84FF"), Color(hex: "5AC8FA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("暂无进行中的计时器")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "1C1C1E"))

                Text("点击右上角 + 按钮创建")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    private var timersListSection: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(timerManager.activeTimers) { timer in
                    ModernTimerCard(
                        timer: timer,
                        isHovered: hoveredTimerId == timer.id,
                        onPauseResume: {
                            if timer.isActive {
                                timerManager.pauseTimer(timer)
                            } else {
                                timerManager.resumeTimer(timer)
                            }
                        },
                        onStart: {
                            timerManager.startTimer(timer)
                        },
                        onTestReminder: {
                            timerManager.testReminder(for: timer)
                        },
                        onEdit: {
                            selectedTimer = timer
                            showingEditTimer = true
                        },
                        onDelete: {
                            timerToDelete = timer
                            showingDeleteConfirmation = true
                        }
                    )
                    .environmentObject(timerManager)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredTimerId = hovering ? timer.id : nil
                        }
                    }
                }
            }
            .padding(14)
        }
        .frame(maxHeight: 320)
    }

    private var footerSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "34C759"))
                    .frame(width: 6, height: 6)

                Text("\(timerManager.timers.count) 个计时器")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8E8E93"))
            }

            Spacer()

            Button(action: openMainWindow) {
                Text("打开主窗口")
                    .compactButtonStyle(color: Color(hex: "0A84FF"), isHovered: isHoveringOpenMain)
            }
            .buttonStyle(PlainButtonStyle())
            .help("打开主窗口")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringOpenMain = hovering
                }
            }

            Button(action: { NSApp.terminate(nil) }) {
                Text("退出")
                    .compactButtonStyle(color: Color(hex: "FF3B30"), isHovered: isHoveringQuit)
            }
            .buttonStyle(PlainButtonStyle())
            .help("退出应用")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringQuit = hovering
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
struct ModernTimerCard: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var timer: CountdownTimer
    let isHovered: Bool
    let onPauseResume: () -> Void
    let onStart: () -> Void
    let onTestReminder: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var hoveredButtonId: String?
    @State private var pressedButtonId: String?

    private var formattedTime: String {
        timerManager.formatTime(timer.remainingTime)
    }

    var body: some View {
        HStack(spacing: 10) {
            // 左侧：图标和计时器信息
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(statusBackgroundColor)
                        .frame(width: 36, height: 36)
                        .shadow(color: statusColor.opacity(0.2), radius: 3, x: 0, y: 1)

                    Image(systemName: timer.icon ?? "timer")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .lineLimit(1)

                    Text(formattedTime)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(timer.isPaused ? Color(hex: "FF9500") : Color(hex: "8E8E93"))
                }
            }

            Spacer()

            // 右侧：四个操作图标按钮（与倒计时信息同一水平线）
            HStack(spacing: 6) {
                // 暂停/继续按钮
                iconButton(
                    id: "pauseResume",
                    icon: timer.isActive ? "pause.fill" : "play.fill",
                    color: timer.isActive ? Color(hex: "FF9500") : Color(hex: "34C759"),
                    action: timer.isActive ? onPauseResume : onStart
                )

                // 生效按钮
                iconButton(
                    id: "test",
                    icon: "bell.fill",
                    color: Color(hex: "34C759"),
                    action: onTestReminder
                )

                // 编辑按钮
                iconButton(
                    id: "edit",
                    icon: "pencil",
                    color: Color(hex: "0A84FF"),
                    action: onEdit
                )

                // 删除按钮
                iconButton(
                    id: "delete",
                    icon: "trash",
                    color: Color(hex: "FF3B30"),
                    action: onDelete
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.white.opacity(0.9) : Color.white.opacity(0.6))
                .shadow(
                    color: isHovered ? Color.black.opacity(0.08) : Color.black.opacity(0.03),
                    radius: isHovered ? 6 : 3,
                    x: 0,
                    y: isHovered ? 3 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isHovered ? statusColor.opacity(0.3) : Color.white.opacity(0.5),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }

    private func iconButton(id: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        let isButtonHovered = hoveredButtonId == id
        let isButtonPressed = pressedButtonId == id

        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(isButtonHovered ? 0.2 : 0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(isButtonHovered ? 0.4 : 0.25), lineWidth: isButtonHovered ? 1.5 : 1)
                )
                .shadow(
                    color: color.opacity(isButtonHovered ? 0.3 : 0),
                    radius: isButtonHovered ? 4 : 0,
                    x: 0,
                    y: isButtonHovered ? 2 : 0
                )
                .scaleEffect(isButtonPressed ? 0.9 : (isButtonHovered ? 1.08 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredButtonId = hovering ? id : nil
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButtonId = id
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressedButtonId = nil
                    }
                }
        )
        .help(buttonHelpText(for: id))
    }

    private func buttonHelpText(for id: String) -> String {
        switch id {
        case "pauseResume":
            return timer.isActive ? "暂停" : "继续"
        case "test":
            return "测试提醒"
        case "edit":
            return "编辑"
        case "delete":
            return "删除"
        default:
            return ""
        }
    }

    private var statusColor: Color {
        if timer.isActive {
            return Color(hex: "34C759")
        } else if timer.isPaused {
            return Color(hex: "FF9500")
        }
        return Color(hex: "8E8E93")
    }

    private var statusBackgroundColor: Color {
        if timer.isActive {
            return Color(hex: "34C759").opacity(0.12)
        } else if timer.isPaused {
            return Color(hex: "FF9500").opacity(0.12)
        }
        return Color(hex: "8E8E93").opacity(0.1)
    }
}
