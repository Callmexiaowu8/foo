import SwiftUI

/// 菜单栏弹窗视图
/// 显示活跃计时器和控制选项，确保与主应用状态同步
@available(macOS 14.0, *)
struct MenuBarPopoverView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var hoveredItemId: UUID?
    @State private var isClosing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            Divider()
            
            // 活跃计时器区域
            if !timerManager.activeTimers.isEmpty {
                activeTimersSection
                Divider()
            }
            
            // 快捷操作
            quickActionsSection
            
            // 倒计时列表
            if !timerManager.timers.isEmpty {
                Divider()
                timerListSection
            }
            
            Divider()
            
            // 底部工具栏
            footerView
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("倒计时提醒")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            Spacer()
            
            // 显示模式切换
            Menu {
                ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                    Button(action: {
                        MenuBarManager.shared.setDisplayMode(mode)
                    }) {
                        HStack {
                            Text(mode.rawValue)
                            if MenuBarManager.shared.displayMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            // 打开主窗口按钮
            Button(action: {
                MenuBarManager.shared.showMainWindow()
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Active Timers Section
    private var activeTimersSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("进行中 (\(timerManager.activeTimers.count))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(timerManager.activeTimers) { timer in
                        ActiveTimerRow(timer: timer)
                            .environmentObject(timerManager)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 150)
        }
        .background(Color.accentColor.opacity(0.05))
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            // 全部暂停/继续
            if !timerManager.activeTimers.isEmpty {
                let allPaused = timerManager.activeTimers.allSatisfy { $0.isPaused }
                MenuBarActionRow(
                    icon: allPaused ? "play.fill" : "pause.fill",
                    title: allPaused ? "全部继续" : "全部暂停",
                    color: allPaused ? .green : .orange
                ) {
                    toggleAllTimers()
                }
            }
            
            // 全部停止
            if !timerManager.activeTimers.isEmpty {
                MenuBarActionRow(
                    icon: "stop.fill",
                    title: "全部停止",
                    color: .red
                ) {
                    stopAllTimers()
                }
            }
            
            // 新建倒计时
            MenuBarActionRow(
                icon: "plus",
                title: "新建倒计时",
                color: .accentColor
            ) {
                MenuBarManager.shared.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: AppNotifications.showAddTimerSheet, object: nil)
                    MenuBarManager.shared.showMainWindow()
                }
            }
            
            // 打开主窗口
            MenuBarActionRow(
                icon: "window",
                title: "打开主窗口",
                color: .secondary
            ) {
                MenuBarManager.shared.showMainWindow()
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Timer List Section
    private var timerListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("所有倒计时")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(timerManager.timers.prefix(5)) { timer in
                        TimerListRow(
                            timer: timer,
                            isHovered: hoveredItemId == timer.id
                        )
                        .environmentObject(timerManager)
                        .onHover { isHovered in
                            hoveredItemId = isHovered ? timer.id : nil
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 120)
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        HStack {
            Text("\(timerManager.timers.count) 个任务")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Text("退出")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Actions
    private func toggleAllTimers() {
        let allPaused = timerManager.activeTimers.allSatisfy { $0.isPaused }
        for timer in timerManager.activeTimers {
            if allPaused && timer.isPaused {
                timerManager.resumeTimer(timer)
            } else if !allPaused && timer.isActive {
                timerManager.pauseTimer(timer)
            }
        }
    }
    
    private func stopAllTimers() {
        for timer in timerManager.activeTimers {
            timerManager.stopTimer(timer)
        }
    }
}

// MARK: - Active Timer Row
/// 活跃计时器行视图
/// 使用 @ObservedObject 绑定 timer，确保时间变化时自动刷新
@available(macOS 14.0, *)
struct ActiveTimerRow: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var timer: CountdownTimer
    
    var body: some View {
        HStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(isTimerActive ? Color.accentColor.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(isTimerActive ? .accentColor : .orange)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 1) {
                Text(timer.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isTimerActive ? Color.green : Color.orange)
                        .frame(width: 5, height: 5)
                    
                    Text(isTimerActive ? "进行中" : "已暂停")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 时间显示 - 直接读取 timer.remainingTime 确保实时
            Text(formattedTime)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
            
            // 控制按钮
            HStack(spacing: 4) {
                if isTimerActive {
                    Button(action: {
                        timerManager.pauseTimer(timer)
                    }) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.orange))
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        timerManager.resumeTimer(timer)
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.green))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    timerManager.stopTimer(timer)
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var isTimerActive: Bool {
        timer.isActive && !timer.isPaused
    }
    
    private var formattedTime: String {
        timerManager.formatTime(timer.remainingTime)
    }
    
    private var iconName: String {
        if timer.title.contains("水") { return "drop.fill" }
        else if timer.title.contains("休息") || timer.title.contains("息") { return "bed.double.fill" }
        else if timer.title.contains("工作") || timer.title.contains("专注") { return "briefcase.fill" }
        else if timer.title.contains("运动") || timer.title.contains("锻炼") { return "figure.walk" }
        else { return "timer" }
    }
}

// MARK: - Menu Bar Action Row
@available(macOS 14.0, *)
struct MenuBarActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Timer List Row
@available(macOS 14.0, *)
struct TimerListRow: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var timer: CountdownTimer
    let isHovered: Bool
    
    var body: some View {
        Button(action: {
            if timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer) {
                timerManager.stopTimer(timer)
            } else {
                timerManager.startTimer(timer)
            }
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer)
                              ? Color.accentColor.opacity(0.15)
                              : Color.secondary.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 10))
                        .foregroundColor(timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer)
                                         ? .accentColor
                                         : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(timer.title)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    
                    Text(timer.formattedDuration)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer) {
                    Text(timerManager.formatTime(timer.remainingTime))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(timerManager.isTimerActive(timer) || timerManager.isTimerPaused(timer)
                          ? Color.accentColor.opacity(0.05)
                          : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        if timer.title.contains("水") { return "drop.fill" }
        else if timer.title.contains("休息") || timer.title.contains("息") { return "bed.double.fill" }
        else if timer.title.contains("工作") || timer.title.contains("专注") { return "briefcase.fill" }
        else if timer.title.contains("运动") || timer.title.contains("锻炼") { return "figure.walk" }
        else { return "timer" }
    }
}
