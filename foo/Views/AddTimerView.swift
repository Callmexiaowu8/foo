import SwiftUI

@available(macOS 14.0, *)
struct AddTimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var hours = 0
    @State private var minutes = 25
    @State private var hoursText = "0"
    @State private var minutesText = "25"
    @State private var soundEnabled = true
    @State private var autoDismissSeconds: Int = 15
    @State private var selectedIcon: String? = nil
    
    private var totalMinutes: Int {
        hours * 60 + minutes
    }
    
    private var isValid: Bool {
        !title.isEmpty && totalMinutes > 0
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                Divider()
                    .background(AppColors.divider)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        basicInfoCard
                        durationCard
                        optionsCard
                        
                        if !isDurationValid {
                            validationWarning
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .frame(width: 480, height: 600)
    }
    
    private var isDurationValid: Bool {
        totalMinutes > 0
    }
    
    private var validationWarning: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.warning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("时长必须大于0")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.warning)
                    .fontWeight(.medium)
                
                Text("请调整小时或分钟的值")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(AppColors.warning.opacity(0.1))
        )
        .transition(.opacity.combined(with: .scale))
    }
    
    private var headerBar: some View {
        HStack {
            Button("取消") { dismiss() }
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text("新建倒计时")
                .font(AppFonts.headline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button("创建") { createTimer() }
                .disabled(!isValid)
                .font(AppFonts.callout.weight(.semibold))
                .foregroundColor(isValid ? AppColors.primary : AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
    }
    
    // MARK: - 基本信息卡片
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("基本信息", systemImage: "textformat")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack(alignment: .center, spacing: AppSpacing.lg) {
                IconSelector(selectedIcon: $selectedIcon)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    FormField(label: "标题") {
                        TextField("例如：喝水、休息", text: $title)
                            .font(AppFonts.body)
                    }

                    FormField(label: "描述（可选）") {
                        TextField("添加详细说明...", text: $description)
                            .font(AppFonts.body)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
    
    // MARK: - 时长卡片 - 双重调节机制
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("时长设置", systemImage: "clock")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.xl) {
                    DualTimeInput(
                        title: "小时",
                        value: $hours,
                        textValue: $hoursText,
                        range: 0..<24
                    )
                    
                    DualTimeInput(
                        title: "分钟",
                        value: $minutes,
                        textValue: $minutesText,
                        range: 0..<60
                    )
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - 选项卡片
    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("提醒选项", systemImage: "bell.badge")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                ToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "启用声音",
                    subtitle: "倒计时结束时播放提示音",
                    isOn: $soundEnabled
                )

                Divider()
                    .padding(.leading, 44)

                AutoDismissSelector(
                    seconds: $autoDismissSeconds,
                    label: "自动消失时间"
                )
            }
        }
        .cardStyle()
    }
    
    private var formattedTotalTime: String {
        if hours > 0 && minutes > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if hours > 0 {
            return "\(hours)小时"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func createTimer() {
        let duration = TimeInterval(totalMinutes * 60)

        let timer = CountdownTimer(
            title: title,
            description: description,
            duration: duration,
            repeatFrequency: .daily,
            soundEnabled: soundEnabled,
            autoDismissSeconds: autoDismissSeconds,
            icon: selectedIcon
        )

        timerManager.addTimer(timer)
        dismiss()
    }
}

// MARK: - Form Field

@available(macOS 14.0, *)
struct FormField<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)

            content
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md)
                        .fill(AppColors.cardBackground)
                        .shadow(
                            color: AppShadows.sm.color,
                            radius: AppShadows.sm.radius,
                            x: AppShadows.sm.x,
                            y: AppShadows.sm.y
                        )
                )
        }
    }
}

// MARK: - Dual Time Input (Input + Stepper)

@available(macOS 14.0, *)
struct DualTimeInput: View {
    let title: String
    @Binding var value: Int
    @Binding var textValue: String
    let range: Range<Int>
    
    @State private var isEditing = false
    @State private var isHovering = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: AppSpacing.xs) {
                stepButton(systemName: "minus", action: decrement)
                
                textInputField
                
                stepButton(systemName: "plus", action: increment)
            }
            .padding(AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .stroke(borderColor, lineWidth: isFocused ? 2 : (isHovering ? 1 : 0))
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            withAnimation(AppAnimations.fast) {
                isHovering = hovering
            }
        }
    }
    
    private var textInputField: some View {
        TextField("", text: $textValue)
            .font(AppFonts.title2.monospacedDigit())
            .foregroundColor(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .frame(minWidth: 50)
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                validateAndUpdate(newValue: newValue)
            }
            .onChange(of: value) { _, newValue in
                if !isEditing && textValue != "\(newValue)" {
                    textValue = "\(newValue)"
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                if isFocused {
                    isFocused = false
                    commitEdit()
                }
            }
    }
    
    private var borderColor: Color {
        if isFocused {
            return AppColors.primary.opacity(0.5)
        }
        return isHovering ? AppColors.divider : Color.clear
    }
    
    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(AppColors.divider.opacity(0.5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func increment() {
        if value < range.upperBound - 1 {
            withAnimation(AppAnimations.fast) {
                value += 1
                textValue = "\(value)"
            }
        }
    }
    
    private func decrement() {
        if value > range.lowerBound {
            withAnimation(AppAnimations.fast) {
                value -= 1
                textValue = "\(value)"
            }
        }
    }
    
    private func validateAndUpdate(newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        if filtered != newValue {
            textValue = filtered
        }

        guard let num = Int(filtered), range.contains(num) else {
            return
        }

        isEditing = true
        value = num
        isEditing = false
    }

    private func commitEdit() {
        guard let num = Int(textValue) else {
            textValue = "\(value)"
            return
        }

        if !range.contains(num) {
            let clamped = max(range.lowerBound, min(range.upperBound - 1, num))
            value = clamped
            textValue = "\(clamped)"
        }
    }
}

// MARK: - Custom Calendar View

@available(macOS 14.0, *)
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date()
    @State private var isHoveringDay: Int? = nil
    
    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter.string(from: displayedMonth)
    }
    
    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            monthNavigation
            
            weekdayHeader
            
            calendarGrid
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(AppColors.background)
        )
    }
    
    private var monthNavigation: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text(monthYearString)
                .font(AppFonts.subheadline.weight(.medium))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isHovering: isHoveringDay == index,
                        isToday: calendar.isDateInToday(date)
                    ) {
                        selectedDate = date
                    }
                    .onHover { hovering in
                        withAnimation(AppAnimations.fast) {
                            isHoveringDay = hovering ? index : nil
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 32)
                }
            }
        }
    }
    
    private func previousMonth() {
        withAnimation(AppAnimations.spring) {
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(AppAnimations.spring) {
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }
}

// MARK: - Day Cell

@available(macOS 14.0, *)
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isHovering: Bool
    let isToday: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }
    
    var body: some View {
        Button(action: action) {
            Text(dayNumber)
                .font(AppFonts.subheadline)
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(backgroundView)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        }
        if isToday {
            return AppColors.primary
        }
        return AppColors.textPrimary
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            Circle()
                .fill(AppColors.primary)
        } else if isToday {
            Circle()
                .stroke(AppColors.primary, lineWidth: 1)
        } else if isHovering {
            Circle()
                .fill(AppColors.primary.opacity(0.1))
        } else {
            Color.clear
        }
    }
}

// MARK: - Time Range Picker

@available(macOS 14.0, *)
struct TimeRangePicker: View {
    let title: String
    @Binding var hour: Int
    @Binding var minute: Int
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: AppSpacing.xs) {
                Picker("", selection: $hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h))
                            .tag(h)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 60)
                
                Text(":")
                    .foregroundColor(AppColors.textSecondary)
                
                Picker("", selection: $minute) {
                    ForEach([0, 15, 30, 45], id: \.self) { m in
                        Text(String(format: "%02d", m))
                            .tag(m)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 60)
            }
            .padding(AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(AppColors.background)
            )
        }
    }
}

// MARK: - Toggle Row

@available(macOS 14.0, *)
struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline.weight(.medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                .labelsHidden()
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Time Range Quick Button

@available(macOS 14.0, *)
struct TimeRangeQuickButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(isSelected ? AppColors.primary : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(isSelected ? AppColors.primary : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Edit Timer View

@available(macOS 14.0, *)
struct EditTimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    let timer: CountdownTimer
    
    @State private var title: String
    @State private var description: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var hoursText: String
    @State private var minutesText: String
    @State private var soundEnabled: Bool
    @State private var autoDismissSeconds: Int
    @State private var showingDiscardAlert = false
    @State private var showingDeleteAlert = false
    @State private var selectedIcon: String?

    private var originalTimerBackup: CountdownTimer

    init(timer: CountdownTimer) {
        self.timer = timer
        _title = State(initialValue: timer.title)
        _description = State(initialValue: timer.timerDescription)
        _hours = State(initialValue: Int(timer.duration) / 3600)
        _minutes = State(initialValue: (Int(timer.duration) % 3600) / 60)
        _hoursText = State(initialValue: "\(Int(timer.duration) / 3600)")
        _minutesText = State(initialValue: "\((Int(timer.duration) % 3600) / 60)")
        _soundEnabled = State(initialValue: timer.soundEnabled)
        _autoDismissSeconds = State(initialValue: timer.autoDismissSeconds)
        _selectedIcon = State(initialValue: timer.icon)

        self.originalTimerBackup = CountdownTimer(
            title: timer.title,
            description: timer.timerDescription,
            duration: timer.duration,
            repeatFrequency: .once,
            soundEnabled: timer.soundEnabled,
            autoDismissSeconds: timer.autoDismissSeconds,
            icon: timer.icon
        )
    }
    
    private var totalMinutes: Int {
        hours * 60 + minutes
    }
    
    private var hasUnsavedChanges: Bool {
        title != originalTimerBackup.title ||
        description != originalTimerBackup.timerDescription ||
        hours != Int(originalTimerBackup.duration) / 3600 ||
        minutes != (Int(originalTimerBackup.duration) % 3600) / 60
    }
    
    private var isValid: Bool {
        !title.isEmpty && totalMinutes > 0
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                Divider()
                    .background(AppColors.divider)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        basicInfoCard
                        durationCard
                        optionsCard
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .frame(width: 480, height: 720)
        .alert("放弃修改？", isPresented: $showingDiscardAlert) {
            Button("取消", role: .cancel) { }
            Button("放弃", role: .destructive) {
                discardChanges()
            }
        } message: {
            Text("您有未保存的修改。确定要放弃所有更改吗？")
        }
    }
    
    private var headerBar: some View {
        HStack {
            Button("取消") {
                if hasUnsavedChanges {
                    showingDiscardAlert = true
                } else {
                    dismiss()
                }
            }
            .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text("编辑倒计时")
                .font(AppFonts.headline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            HStack(spacing: AppSpacing.md) {
                Button("删除") {
                    showingDeleteAlert = true
                }
                .foregroundColor(AppColors.error)
                .alert("确认删除？", isPresented: $showingDeleteAlert) {
                    Button("取消", role: .cancel) { }
                    Button("删除", role: .destructive) {
                        deleteTimer()
                    }
                } message: {
                    Text("确定要删除 \"\(title)\" 吗？此操作无法撤销。")
                }

                Button("保存") {
                    updateTimer()
                }
                .disabled(!isValid)
                .font(AppFonts.callout.weight(.semibold))
                .foregroundColor(isValid ? AppColors.primary : AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
    }
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("基本信息", systemImage: "textformat")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(alignment: .center, spacing: AppSpacing.lg) {
                IconSelector(selectedIcon: $selectedIcon)
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    FormField(label: "标题") {
                        TextField("例如：喝水、休息", text: $title)
                            .font(AppFonts.body)
                    }
                    
                    FormField(label: "描述（可选）") {
                        TextField("添加详细说明...", text: $description)
                            .font(AppFonts.body)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
    
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("时长设置", systemImage: "clock")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.xl) {
                    DualTimeInput(
                        title: "小时",
                        value: $hours,
                        textValue: $hoursText,
                        range: 0..<24
                    )
                    
                    DualTimeInput(
                        title: "分钟",
                        value: $minutes,
                        textValue: $minutesText,
                        range: 0..<60
                    )
                }
                
            }
        }
        .cardStyle()
    }
    
    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("提醒选项", systemImage: "bell.badge")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                ToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "启用声音",
                    subtitle: "倒计时结束时播放提示音",
                    isOn: $soundEnabled
                )

                Divider()
                    .padding(.leading, 44)

                AutoDismissSelector(
                    seconds: $autoDismissSeconds,
                    label: "自动消失时间"
                )
            }
        }
        .cardStyle()
    }
    
    private var deleteButton: some View {
        Button(action: { deleteTimer() }) {
            HStack {
                Spacer()
                Image(systemName: "trash")
                Text("删除倒计时")
                Spacer()
            }
            .font(AppFonts.callout.weight(.semibold))
            .foregroundColor(AppColors.error)
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .fill(AppColors.error.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedTotalTime: String {
        if hours > 0 && minutes > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if hours > 0 {
            return "\(hours)小时"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func updateTimer() {
        timer.title = title
        timer.timerDescription = description
        timer.duration = TimeInterval(totalMinutes * 60)
        timer.repeatFrequency = .once
        timer.endDate = nil
        timer.soundEnabled = soundEnabled
        timer.autoDismissSeconds = autoDismissSeconds
        timer.icon = selectedIcon

        if !timer.isActive {
            timer.remainingTime = timer.duration
        }

        timerManager.updateTimer(timer)
        dismiss()
    }
    
    private func deleteTimer() {
        timerManager.deleteTimer(timer)
        dismiss()
    }
    
    private func discardChanges() {
        dismiss()
    }
}
