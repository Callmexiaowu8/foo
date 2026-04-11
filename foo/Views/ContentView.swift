import SwiftUI

@available(macOS 14.0, *)
struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingAddTimer = false
    @State private var selectedTimer: CountdownTimer?
    @State private var showingEditTimer = false
    @State private var hoveredTimerId: UUID?
    @State private var showingDeleteConfirmation = false
    @State private var timerToDelete: CountdownTimer?

    private var sortedTimers: [CountdownTimer] {
        timerManager.timers.sorted { timer1, timer2 in
            let t1Running = timer1.isActive && !timer1.isPaused
            let t2Running = timer2.isActive && !timer2.isPaused
            let t1Paused = timer1.isPaused
            let t2Paused = timer2.isPaused
            
            // 优先级1: 运行中的计时器排在最前
            if t1Running && !t2Running { return true }
            if !t1Running && t2Running { return false }
            
            // 优先级2: 都在运行中，按剩余时间升序（即将完成的在前）
            if t1Running && t2Running {
                return timer1.remainingTime < timer2.remainingTime
            }
            
            // 优先级3: 已暂停的计时器排在未开始之前
            if t1Paused && !t2Paused { return true }
            if !t1Paused && t2Paused { return false }
            
            // 优先级4: 都已暂停，按剩余时间升序
            if t1Paused && t2Paused {
                return timer1.remainingTime < timer2.remainingTime
            }
            
            // 优先级5: 都未开始，按创建时间倒序（最新创建的在前）
            return timer1.createdAt > timer2.createdAt
        }
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                Divider()
                    .background(AppColors.divider)

                timersListSection

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

    private var headerSection: some View {
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

            HStack(spacing: AppSpacing.md) {
                if !timerManager.activeTimers.isEmpty {
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 8, height: 8)

                        Text("\(timerManager.activeTimers.count) 进行中")
                            .font(AppFonts.footnote)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        Capsule()
                            .fill(AppColors.success.opacity(0.1))
                    )
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
    }

    private var timersListSection: some View {
        ScrollView {
            if timerManager.timers.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: AppSpacing.md) {
                    ForEach(sortedTimers) { timer in
                        UnifiedTimerRow(
                            timer: timer,
                            isHovered: hoveredTimerId == timer.id,
                            onToggle: { toggleTimer(timer) },
                            onStart: { timerManager.startTimer(timer) },
                            onPause: { timerManager.pauseTimer(timer) },
                            onResume: { timerManager.resumeTimer(timer) },
                            onReset: { timerManager.resetTimer(timer) },
                            onSkip: { timerManager.skipTimer(timer) },
                            onDelete: {
                                timerToDelete = timer
                                showingDeleteConfirmation = true
                            }
                        )
                        .environmentObject(timerManager)
                        .onHover { isHovered in
                            withAnimation(AppAnimations.fast) {
                                hoveredTimerId = isHovered ? timer.id : nil
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.6), AppColors.primaryLight.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: AppSpacing.sm) {
                Text("暂无计时器")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textPrimary)

                Text("点击下方按钮创建一个新的计时器")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private var bottomToolbar: some View {
        HStack {
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

            Text("\(timerManager.timers.count) 个计时器")
                .font(AppFonts.footnote)
                .foregroundColor(AppColors.textSecondary)
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

    private func toggleTimer(_ timer: CountdownTimer) {
        withAnimation(AppAnimations.spring) {
            if timer.isActive {
                timerManager.stopTimer(timer)
            } else {
                timerManager.startTimer(timer)
            }
        }
    }
}

@available(macOS 14.0, *)
struct UnifiedTimerRow: View {
    @ObservedObject var timer: CountdownTimer
    let isHovered: Bool
    let onToggle: () -> Void
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onReset: () -> Void
    let onSkip: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var timerManager: TimerManager
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 52, height: 52)

                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(timer.title)
                        .font(AppFonts.callout.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.sm) {
                        Label(timer.formattedDuration, systemImage: "clock")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Text("•")
                            .foregroundColor(AppColors.textTertiary)

                        Text(timer.repeatFrequency.description)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                if timer.isActive || timer.isPaused {
                    Text(timerManager.formatTime(timer.remainingTime))
                        .font(AppFonts.title3.monospacedDigit())
                        .foregroundColor(timer.isActive ? AppColors.primary : AppColors.warning)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(timer.isActive ? AppColors.primary.opacity(0.1) : AppColors.warning.opacity(0.1))
                        )
                }
            }

            if timer.isActive || timer.isPaused {
                progressBar
            }

            controlButtons
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: isHovered ? AppShadows.lg.color : AppShadows.md.color,
                    radius: isHovered ? AppShadows.lg.radius : AppShadows.md.radius,
                    x: 0,
                    y: isHovered ? 6 : 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .stroke(borderColor, lineWidth: isHovered ? 1.5 : 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            onToggle()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onDelete()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppAnimations.fast) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AppAnimations.fast) {
                        isPressed = false
                    }
                }
        )
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppCornerRadius.full)
                    .fill(AppColors.divider)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: AppCornerRadius.full)
                    .fill(progressColor)
                    .frame(width: max(0, geometry.size.width * CGFloat(timer.progress)), height: 4)
                    .animation(AppAnimations.slow, value: timer.progress)
            }
        }
        .frame(height: 4)
    }

    private var controlButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            if timer.isActive {
                controlButton(title: "暂停", icon: "pause.fill", color: AppColors.warning, action: onPause)
                controlButton(title: "重置", icon: "arrow.counterclockwise", color: AppColors.textSecondary, action: onReset)
            } else if timer.isPaused {
                controlButton(title: "继续", icon: "play.fill", color: AppColors.success, action: onResume)
                controlButton(title: "重置", icon: "arrow.counterclockwise", color: AppColors.textSecondary, action: onReset)
            } else {
                controlButton(title: "开始", icon: "play.fill", color: AppColors.success, action: onStart)
            }

            Spacer()

            if timer.repeatFrequency != .once {
                controlButton(title: "跳过", icon: "forward.fill", color: AppColors.textSecondary, action: onSkip)
            }

            controlButton(title: "删除", icon: "trash", color: AppColors.error, action: onDelete)
        }
    }

    private func controlButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(AppFonts.caption.weight(.medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var iconName: String {
        let lowercased = timer.title.lowercased()
        if lowercased.contains("水") || lowercased.contains("喝") {
            return "drop.fill"
        } else if lowercased.contains("休息") || lowercased.contains("睡眠") {
            return "bed.double.fill"
        } else if lowercased.contains("工作") || lowercased.contains("专注") {
            return "briefcase.fill"
        } else if lowercased.contains("运动") || lowercased.contains("锻炼") || lowercased.contains("跑步") {
            return "figure.walk"
        } else if lowercased.contains("吃饭") || lowercased.contains("午餐") || lowercased.contains("晚餐") {
            return "fork.knife"
        } else if lowercased.contains("学习") || lowercased.contains("读书") {
            return "book.fill"
        }
        return "timer"
    }

    private var iconBackgroundColor: Color {
        if timer.isActive {
            return AppColors.primary.opacity(0.15)
        } else if timer.isPaused {
            return AppColors.warning.opacity(0.15)
        }
        return AppColors.divider.opacity(0.5)
    }

    private var iconColor: Color {
        if timer.isActive {
            return AppColors.primary
        } else if timer.isPaused {
            return AppColors.warning
        }
        return AppColors.textSecondary
    }

    private var progressColor: Color {
        if timer.isActive {
            return AppColors.primary
        } else if timer.isPaused {
            return AppColors.warning
        }
        return AppColors.divider
    }

    private var borderColor: Color {
        if timer.isActive {
            return isHovered ? AppColors.primary.opacity(0.4) : AppColors.primary.opacity(0.2)
        } else if timer.isPaused {
            return isHovered ? AppColors.warning.opacity(0.4) : AppColors.warning.opacity(0.2)
        }
        return isHovered ? AppColors.divider : Color.clear
    }
}
