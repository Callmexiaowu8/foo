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
    @State private var isRepeatEnabled = false
    @State private var repeatFrequency: RepeatFrequency = .once
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(86400 * 30)
    @State private var soundEnabled = true
    @State private var showFullscreenAlert = true
    @State private var hasTimeRange = false
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 18
    @State private var endMinute = 0
    
    private var totalMinutes: Int {
        hours * 60 + minutes
    }
    
    private var isValid: Bool {
        !title.isEmpty && totalMinutes > 0 && isTimeRangeValid
    }
    
    private var isTimeRangeValid: Bool {
        if !hasTimeRange { return true }
        return (startHour * 60 + startMinute) < (endHour * 60 + endMinute)
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
                        repeatCard
                        timeRangeCard
                        optionsCard
                        previewCard
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .frame(width: 480, height: 720)
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
            
            VStack(spacing: AppSpacing.md) {
                FormField(label: "标题") {
                    TextField("例如：喝水、休息", text: $title)
                        .font(AppFonts.body)
                }
                
                FormField(label: "描述（可选）") {
                    TextField("添加详细说明...", text: $description)
                        .font(AppFonts.body)
                }
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
                
                totalDurationDisplay
            }
        }
        .cardStyle()
    }
    
    private var totalDurationDisplay: some View {
        HStack {
            Text("总时长")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(formattedTotalTime)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(AppColors.primary.opacity(0.1))
        )
    }
    
    // MARK: - 重复设置卡片 - Toggle Switch
    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("重复设置", systemImage: "repeat")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Toggle("", isOn: $isRepeatEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .labelsHidden()
            }

            if isRepeatEnabled {
                VStack(spacing: AppSpacing.sm) {
                    CompactFrequencySelector(selection: $repeatFrequency)

                    if repeatFrequency != .once {
                        endDateSection
                    }
                }
                .padding(.top, AppSpacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }
    
    private var endDateSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Toggle("设置结束日期", isOn: $hasEndDate)
                .font(AppFonts.subheadline)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
            
            if hasEndDate {
                CustomCalendarView(selectedDate: $endDate)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }
    
    // MARK: - 时间段设置卡片
    private var timeRangeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("提醒时间段", systemImage: "clock.badge.checkmark")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $hasTimeRange)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
            
            if hasTimeRange {
                VStack(spacing: AppSpacing.md) {
                    Text("在以下时间段内才会触发提醒")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: AppSpacing.lg) {
                        TimeRangePicker(
                            title: "开始",
                            hour: $startHour,
                            minute: $startMinute
                        )
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(AppColors.textTertiary)
                        
                        TimeRangePicker(
                            title: "结束",
                            hour: $endHour,
                            minute: $endMinute
                        )
                    }
                    
                    if !isTimeRangeValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.error)
                            Text("结束时间必须晚于开始时间")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.error)
                        }
                    }
                }
                .padding(.top, AppSpacing.xs)
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
                
                ToggleRow(
                    icon: "rectangle.inset.filled",
                    title: "全屏提醒",
                    subtitle: "以全屏方式显示提醒",
                    isOn: $showFullscreenAlert
                )
            }
        }
        .cardStyle()
    }
    
    // MARK: - 预览卡片
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("预览", systemImage: "eye")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title.isEmpty ? "未命名" : title)
                        .font(AppFonts.callout.weight(.semibold))
                        .foregroundColor(title.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                    
                    Text(formattedTotalTime)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if hasTimeRange && isTimeRangeValid {
                        Text(formattedTimeRange)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Spacer()
                
                if !title.isEmpty && isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                        .font(.system(size: 24))
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .fill(AppColors.background)
            )
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
    
    private var formattedTimeRange: String {
        String(format: "%02d:%02d - %02d:%02d", startHour, startMinute, endHour, endMinute)
    }
    
    private func createTimer() {
        let duration = TimeInterval(totalMinutes * 60)
        let finalEndDate = (isRepeatEnabled && repeatFrequency != .once && hasEndDate) ? endDate : nil
        let finalRepeatFrequency: RepeatFrequency = isRepeatEnabled ? repeatFrequency : .once

        let timer = CountdownTimer(
            title: title,
            description: description,
            duration: duration,
            repeatFrequency: finalRepeatFrequency,
            endDate: finalEndDate,
            soundEnabled: soundEnabled,
            showFullscreenAlert: showFullscreenAlert
        )
        
        timer.reminderStartHour = startHour
        timer.reminderStartMinute = startMinute
        timer.reminderEndHour = endHour
        timer.reminderEndMinute = endMinute
        timer.hasTimeRange = hasTimeRange

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

// MARK: - Compact Frequency Selector

@available(macOS 14.0, *)
struct CompactFrequencySelector: View {
    @Binding var selection: RepeatFrequency
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(RepeatFrequency.selectableCases, id: \.self) { frequency in
                CompactFrequencyButton(
                    frequency: frequency,
                    isSelected: selection == frequency
                ) {
                    withAnimation(AppAnimations.spring) {
                        selection = frequency
                    }
                }
            }
        }
    }
}

@available(macOS 14.0, *)
struct CompactFrequencyButton: View {
    let frequency: RepeatFrequency
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: frequency.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                
                Text(frequency.description)
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .fill(isSelected ? AppColors.primary.opacity(0.1) : AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .stroke(isSelected ? AppColors.primary.opacity(0.3) : (isHovering ? AppColors.divider : Color.clear), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(AppAnimations.fast) {
                isHovering = hovering
            }
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
    @State private var isRepeatEnabled: Bool
    @State private var repeatFrequency: RepeatFrequency
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var soundEnabled: Bool
    @State private var showFullscreenAlert: Bool
    @State private var hasTimeRange: Bool
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int
    
    init(timer: CountdownTimer) {
        self.timer = timer
        _title = State(initialValue: timer.title)
        _description = State(initialValue: timer.timerDescription)
        _hours = State(initialValue: Int(timer.duration) / 3600)
        _minutes = State(initialValue: (Int(timer.duration) % 3600) / 60)
        _hoursText = State(initialValue: "\(Int(timer.duration) / 3600)")
        _minutesText = State(initialValue: "\((Int(timer.duration) % 3600) / 60)")
        _isRepeatEnabled = State(initialValue: timer.repeatFrequency != .once)
        _repeatFrequency = State(initialValue: timer.repeatFrequency)
        _hasEndDate = State(initialValue: timer.endDate != nil)
        _endDate = State(initialValue: timer.endDate ?? Date().addingTimeInterval(86400 * 30))
        _soundEnabled = State(initialValue: timer.soundEnabled)
        _showFullscreenAlert = State(initialValue: timer.showFullscreenAlert)
        _hasTimeRange = State(initialValue: timer.hasTimeRange)
        _startHour = State(initialValue: timer.reminderStartHour)
        _startMinute = State(initialValue: timer.reminderStartMinute)
        _endHour = State(initialValue: timer.reminderEndHour)
        _endMinute = State(initialValue: timer.reminderEndMinute)
    }
    
    private var totalMinutes: Int {
        hours * 60 + minutes
    }
    
    private var isValid: Bool {
        !title.isEmpty && totalMinutes > 0 && isTimeRangeValid
    }
    
    private var isTimeRangeValid: Bool {
        if !hasTimeRange { return true }
        return (startHour * 60 + startMinute) < (endHour * 60 + endMinute)
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
                        repeatCard
                        timeRangeCard
                        optionsCard
                        deleteButton
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .frame(width: 480, height: 780)
    }
    
    private var headerBar: some View {
        HStack {
            Button("取消") { dismiss() }
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text("编辑倒计时")
                .font(AppFonts.headline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button("保存") { updateTimer() }
                .disabled(!isValid)
                .font(AppFonts.callout.weight(.semibold))
                .foregroundColor(isValid ? AppColors.primary : AppColors.textTertiary)
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
            
            VStack(spacing: AppSpacing.md) {
                FormField(label: "标题") {
                    TextField("例如：喝水、休息", text: $title)
                        .font(AppFonts.body)
                }
                
                FormField(label: "描述（可选）") {
                    TextField("添加详细说明...", text: $description)
                        .font(AppFonts.body)
                }
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
                
                HStack {
                    Text("总时长")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(formattedTotalTime)
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.primary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md)
                        .fill(AppColors.primary.opacity(0.1))
                )
            }
        }
        .cardStyle()
    }
    
    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("重复设置", systemImage: "repeat")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Toggle("", isOn: $isRepeatEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .labelsHidden()
            }

            if isRepeatEnabled {
                VStack(spacing: AppSpacing.sm) {
                    CompactFrequencySelector(selection: $repeatFrequency)

                    if repeatFrequency != .once {
                        VStack(spacing: AppSpacing.sm) {
                            Toggle("设置结束日期", isOn: $hasEndDate)
                                .font(AppFonts.subheadline)
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))

                            if hasEndDate {
                                CustomCalendarView(selectedDate: $endDate)
                                    .padding(.top, AppSpacing.xs)
                            }
                        }
                    }
                }
                .padding(.top, AppSpacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }
    
    private var timeRangeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("提醒时间段", systemImage: "clock.badge.checkmark")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $hasTimeRange)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
            
            if hasTimeRange {
                VStack(spacing: AppSpacing.md) {
                    Text("在以下时间段内才会触发提醒")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: AppSpacing.lg) {
                        TimeRangePicker(
                            title: "开始",
                            hour: $startHour,
                            minute: $startMinute
                        )
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(AppColors.textTertiary)
                        
                        TimeRangePicker(
                            title: "结束",
                            hour: $endHour,
                            minute: $endMinute
                        )
                    }
                    
                    if !isTimeRangeValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.error)
                            Text("结束时间必须晚于开始时间")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.error)
                        }
                    }
                }
                .padding(.top, AppSpacing.xs)
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
                
                ToggleRow(
                    icon: "rectangle.inset.filled",
                    title: "全屏提醒",
                    subtitle: "以全屏方式显示提醒",
                    isOn: $showFullscreenAlert
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
        let finalRepeatFrequency: RepeatFrequency = isRepeatEnabled ? repeatFrequency : .once
        timer.repeatFrequency = finalRepeatFrequency
        timer.endDate = (isRepeatEnabled && repeatFrequency != .once && hasEndDate) ? endDate : nil
        timer.soundEnabled = soundEnabled
        timer.showFullscreenAlert = showFullscreenAlert
        timer.reminderStartHour = startHour
        timer.reminderStartMinute = startMinute
        timer.reminderEndHour = endHour
        timer.reminderEndMinute = endMinute
        timer.hasTimeRange = hasTimeRange

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
}
