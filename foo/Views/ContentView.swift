import SwiftUI

@available(macOS 14.0, *)
struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingAddTimer = false
    @State private var selectedTimer: CountdownTimer?
    @State private var showingEditTimer = false
    @State private var hoveredTimerId: UUID?

    var body: some View {
        ZStack {
            // 背景渐变
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义标题栏
                HStack {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "timer")
                            .font(AppFonts.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("倒计时提醒")
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.cardBackground)

                Divider()
                    .background(AppColors.divider)

                // 活跃倒计时列表
                if !timerManager.activeTimers.isEmpty {
                    activeTimersSection
                }

                // 倒计时列表
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(timerManager.timers) { timer in
                            TimerRowView(
                                timer: timer,
                                isHovered: hoveredTimerId == timer.id
                            )
                            .environmentObject(timerManager)
                            .onTapGesture {
                                withAnimation(AppAnimations.spring) {
                                    selectedTimer = timer
                                    showingEditTimer = true
                                }
                            }
                            .onHover { isHovered in
                                withAnimation(AppAnimations.fast) {
                                    hoveredTimerId = isHovered ? timer.id : nil
                                }
                            }
                            .contextMenu {
                                TimerContextMenu(timer: timer)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                }

                // 底部工具栏
                bottomToolbar
            }
        }
        .sheet(isPresented: $showingAddTimer) {
            AddTimerView()
                .environmentObject(timerManager)
        }
        .sheet(isPresented: $showingEditTimer) {
            if let timer = selectedTimer {
                EditTimerView(timer: timer)
                    .environmentObject(timerManager)
            }
        }
        .overlay {
            if timerManager.isFullscreenAlertPresented {
                FullscreenAlertView()
                    .environmentObject(timerManager)
                    .transition(.opacity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotifications.showAddTimerSheet)) { _ in
            showingAddTimer = true
        }
        .onAppear {
            if let window = NSApp.windows.first(where: { $0.frame.width >= 400 && $0.frame.height >= 300 }) {
                MenuBarManager.shared.registerMainWindow(window)
            }
        }
        .frame(minWidth: 450, minHeight: 500)
    }

    // MARK: - Active Timers Section
    private var activeTimersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.md) {
                ForEach(timerManager.activeTimers) { timer in
                    ActiveTimerCard(timer: timer)
                        .environmentObject(timerManager)
                        .frame(width: 320)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .background(
            LinearGradient(
                colors: [AppColors.primary.opacity(0.05), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - 底部工具栏
    private var bottomToolbar: some View {
        HStack {
            // 新建按钮
            Button(action: {
                withAnimation(AppAnimations.spring) {
                    showingAddTimer = true
                }
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "plus")
                        .font(AppFonts.callout.weight(.semibold))
                    Text("新建倒计时")
                        .font(AppFonts.callout.weight(.semibold))
                }
                .primaryButtonStyle()
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // 任务计数
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)

                Text("\(timerManager.timers.count) 个任务")
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(AppColors.cardBackground)
                    .shadow(
                        color: AppShadows.sm.color,
                        radius: AppShadows.sm.radius,
                        x: AppShadows.sm.x,
                        y: AppShadows.sm.y
                    )
            )
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            AppColors.cardBackground
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
    }

    private func deleteTimers(at offsets: IndexSet) {
        for index in offsets {
            let timer = timerManager.timers[index]
            withAnimation(AppAnimations.normal) {
                timerManager.deleteTimer(timer)
            }
        }
    }
}

// MARK: - Active Timer Card

@available(macOS 14.0, *)
struct ActiveTimerCard: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var timer: CountdownTimer
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // 顶部信息栏
            HStack {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(timer.title)
                            .font(AppFonts.callout.weight(.semibold))
                            .lineLimit(1)
                            .foregroundColor(AppColors.textPrimary)

                        StatusBadge(isActive: timer.isActive, isPaused: timer.isPaused)
                    }
                }

                Spacer()
            }

            // 倒计时显示
            HStack {
                Spacer()
                Text(timerManager.formatTime(timer.remainingTime))
                    .font(AppFonts.timerDisplayMini)
                    .foregroundColor(timer.isActive && !timer.isPaused ? AppColors.primary : AppColors.textSecondary)
                    .monospacedDigit()
                Spacer()
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppCornerRadius.full)
                        .fill(AppColors.divider)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: AppCornerRadius.full)
                        .fill(
                            timer.isActive && !timer.isPaused ?
                            AppColors.primary :
                            AppColors.textTertiary
                        )
                        .frame(width: max(0, geometry.size.width * CGFloat(timer.progress)), height: 6)
                        .animation(AppAnimations.slow, value: timer.progress)
                }
            }
            .frame(height: 6)

            // 控制按钮
            HStack(spacing: AppSpacing.sm) {
                if timer.isActive && !timer.isPaused {
                    SmallControlButton(
                        title: "暂停",
                        icon: "pause.fill",
                        color: AppColors.warning
                    ) {
                        timerManager.pauseTimer(timer)
                    }

                    SmallControlButton(
                        title: "停止",
                        icon: "stop.fill",
                        color: AppColors.error
                    ) {
                        timerManager.stopTimer(timer)
                    }
                } else if timer.isPaused {
                    SmallControlButton(
                        title: "继续",
                        icon: "play.fill",
                        color: AppColors.success
                    ) {
                        timerManager.resumeTimer(timer)
                    }

                    SmallControlButton(
                        title: "停止",
                        icon: "stop.fill",
                        color: AppColors.error
                    ) {
                        timerManager.stopTimer(timer)
                    }
                }

                Spacer()

                Button(action: { timerManager.skipTimer(timer) }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppColors.divider.opacity(0.5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(AppAnimations.spring) {
                isHovering = hovering
            }
        }
    }

    private var iconName: String {
        if timer.title.contains("水") {
            return "drop.fill"
        } else if timer.title.contains("休息") || timer.title.contains("息") {
            return "bed.double.fill"
        } else if timer.title.contains("工作") || timer.title.contains("专注") {
            return "briefcase.fill"
        } else if timer.title.contains("运动") || timer.title.contains("锻炼") {
            return "figure.walk"
        } else {
            return "timer"
        }
    }
}

// MARK: - Small Control Button

@available(macOS 14.0, *)
struct SmallControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(AppFonts.caption.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onHover { hovering in
            withAnimation(AppAnimations.fast) {
                isPressed = hovering
            }
        }
    }
}

// MARK: - Timer Row View

@available(macOS 14.0, *)
struct TimerRowView: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var timer: CountdownTimer
    let isHovered: Bool
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer) ?
                        AppColors.primary.opacity(0.15) :
                        AppColors.divider.opacity(0.5)
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(
                        timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer) ?
                        AppColors.primary :
                        AppColors.textSecondary
                    )
            }

            // 信息 - 使用固定宽度避免挤压
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(timer.title)
                    .font(AppFonts.callout.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.sm) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(AppFonts.caption)
                        Text(timer.formattedDuration)
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(AppColors.textSecondary)

                    Text("•")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)

                    Text(timer.repeatFrequency.description)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右侧状态
            HStack(spacing: AppSpacing.sm) {
                if timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer) {
                    Text(timerManager.formatTime(timer.remainingTime))
                        .font(AppFonts.callout.monospacedDigit())
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule()
                                .fill(AppColors.primary.opacity(0.1))
                        )
                }

                // 播放/停止按钮
                Button(action: {
                    withAnimation(AppAnimations.spring) {
                        toggleTimer()
                    }
                }) {
                    Image(systemName: timerManager.isTimerActive(timer) ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(timerManager.isTimerActive(timer) ? AppColors.error : AppColors.success)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(timerManager.isTimerActive(timer) ? AppColors.error.opacity(0.1) : AppColors.success.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: isHovered ? AppShadows.md.color : AppShadows.sm.color,
                    radius: isHovered ? AppShadows.md.radius : AppShadows.sm.radius,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .stroke(
                    timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer) ?
                    AppColors.primary.opacity(0.3) :
                    (isHovered ? AppColors.divider : Color.clear),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
        .onHover { hovering in
            withAnimation(AppAnimations.fast) {
                isPressed = hovering
            }
        }
    }

    private var iconName: String {
        if timer.title.contains("水") {
            return "drop.fill"
        } else if timer.title.contains("休息") || timer.title.contains("息") {
            return "bed.double.fill"
        } else if timer.title.contains("工作") || timer.title.contains("专注") {
            return "briefcase.fill"
        } else if timer.title.contains("运动") || timer.title.contains("锻炼") {
            return "figure.walk"
        } else {
            return "timer"
        }
    }

    private func toggleTimer() {
        if timerManager.isTimerActive(timer) {
            timerManager.stopTimer(timer)
        } else {
            timerManager.startTimer(timer)
        }
    }
}

// MARK: - Status Badge

@available(macOS 14.0, *)
struct StatusBadge: View {
    let isActive: Bool
    let isPaused: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(statusText)
                .font(AppFonts.caption.weight(.medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
    }

    private var statusColor: Color {
        if isActive && !isPaused {
            return AppColors.success
        } else if isPaused {
            return AppColors.warning
        } else {
            return AppColors.textSecondary
        }
    }

    private var statusText: String {
        if isActive && !isPaused {
            return "进行中"
        } else if isPaused {
            return "已暂停"
        } else {
            return "未开始"
        }
    }
}

// MARK: - Context Menu

@available(macOS 14.0, *)
struct TimerContextMenu: View {
    @EnvironmentObject var timerManager: TimerManager
    let timer: CountdownTimer

    var body: some View {
        Button(action: { timerManager.startTimer(timer) }) {
            Label("开始", systemImage: "play.fill")
        }

        Button(action: { timerManager.resetTimer(timer) }) {
            Label("重置", systemImage: "arrow.counterclockwise")
        }

        Divider()

        Button(role: .destructive, action: { timerManager.deleteTimer(timer) }) {
            Label("删除", systemImage: "trash")
        }
    }
}
