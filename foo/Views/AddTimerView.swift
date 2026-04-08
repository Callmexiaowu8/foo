import SwiftUI

@available(macOS 14.0, *)
struct AddTimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var hours = 0
    @State private var minutes = 25
    @State private var repeatFrequency: RepeatFrequency = .once
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(86400 * 30)
    @State private var soundEnabled = true
    @State private var showFullscreenAlert = true
    
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
                // 自定义标题栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("新建倒计时")
                        .font(AppFonts.headline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button("创建") {
                        createTimer()
                    }
                    .disabled(!isValid)
                    .font(AppFonts.callout.weight(.semibold))
                    .foregroundColor(isValid ? AppColors.primary : AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.cardBackground)
                
                Divider()
                    .background(AppColors.divider)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        // 基本信息卡片
                        basicInfoCard
                        
                        // 时长选择卡片
                        durationCard
                        
                        // 重复设置卡片
                        repeatCard
                        
                        // 提醒选项卡片
                        optionsCard
                        
                        // 预览卡片
                        previewCard
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .frame(width: 450, height: 650)
    }
    
    // MARK: - 基本信息卡片
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("基本信息", systemImage: "textformat")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                // 标题输入
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("标题")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("例如：喝水、休息", text: $title)
                        .font(AppFonts.body)
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
                
                // 描述输入
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("描述（可选）")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("添加详细说明...", text: $description)
                        .font(AppFonts.body)
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
    }
    
    // MARK: - 时长卡片
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("时长设置", systemImage: "clock")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.lg) {
                // 时间选择器
                HStack(spacing: AppSpacing.lg) {
                    TimePicker(
                        title: "小时",
                        value: $hours,
                        range: 0..<24
                    )
                    
                    TimePicker(
                        title: "分钟",
                        value: $minutes,
                        range: 0..<60
                    )
                }
                
                // 总时长显示
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
    }
    
    // MARK: - 重复设置卡片
    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("重复设置", systemImage: "repeat")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                // 频率选择
                FrequencySelector(selection: $repeatFrequency)
                
                if repeatFrequency != .once {
                    Toggle("设置结束日期", isOn: $hasEndDate)
                        .font(AppFonts.subheadline)
                    
                    if hasEndDate {
                        DatePicker("", selection: $endDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                    .fill(AppColors.background)
                            )
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
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
                }
                
                Spacer()
                
                if !title.isEmpty {
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
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
        let finalEndDate = (repeatFrequency != .once && hasEndDate) ? endDate : nil

        let timer = CountdownTimer(
            title: title,
            description: description,
            duration: duration,
            repeatFrequency: repeatFrequency,
            endDate: finalEndDate,
            soundEnabled: soundEnabled,
            showFullscreenAlert: showFullscreenAlert
        )

        timerManager.addTimer(timer)
        dismiss()
    }
}

// MARK: - Time Picker

@available(macOS 14.0, *)
struct TimePicker: View {
    let title: String
    @Binding var value: Int
    let range: Range<Int>
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: AppSpacing.xs) {
                Button(action: { 
                    if value > range.lowerBound {
                        withAnimation(AppAnimations.fast) {
                            value -= 1
                        }
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppColors.divider.opacity(0.5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("\(value)")
                    .font(AppFonts.title2.monospacedDigit())
                    .foregroundColor(AppColors.textPrimary)
                    .frame(minWidth: 50)
                
                Button(action: { 
                    if value < range.upperBound - 1 {
                        withAnimation(AppAnimations.fast) {
                            value += 1
                        }
                    }
                }) {
                    Image(systemName: "plus")
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
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .stroke(isHovering ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
            .onHover { hovering in
                withAnimation(AppAnimations.fast) {
                    isHovering = hovering
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Frequency Selector

@available(macOS 14.0, *)
struct FrequencySelector: View {
    @Binding var selection: RepeatFrequency
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(RepeatFrequency.allCases, id: \.self) { frequency in
                FrequencyButton(
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
struct FrequencyButton: View {
    let frequency: RepeatFrequency
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(frequency.description)
                    .font(AppFonts.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 20))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(AppSpacing.md)
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
    @State private var repeatFrequency: RepeatFrequency
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var soundEnabled: Bool
    @State private var showFullscreenAlert: Bool
    
    init(timer: CountdownTimer) {
        self.timer = timer
        _title = State(initialValue: timer.title)
        _description = State(initialValue: timer.timerDescription)
        _hours = State(initialValue: Int(timer.duration) / 3600)
        _minutes = State(initialValue: (Int(timer.duration) % 3600) / 60)
        _repeatFrequency = State(initialValue: timer.repeatFrequency)
        _hasEndDate = State(initialValue: timer.endDate != nil)
        _endDate = State(initialValue: timer.endDate ?? Date().addingTimeInterval(86400 * 30))
        _soundEnabled = State(initialValue: timer.soundEnabled)
        _showFullscreenAlert = State(initialValue: timer.showFullscreenAlert)
    }
    
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
                // 自定义标题栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("编辑倒计时")
                        .font(AppFonts.headline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button("保存") {
                        updateTimer()
                    }
                    .disabled(!isValid)
                    .font(AppFonts.callout.weight(.semibold))
                    .foregroundColor(isValid ? AppColors.primary : AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.cardBackground)
                
                Divider()
                    .background(AppColors.divider)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        // 基本信息卡片
                        basicInfoCard
                        
                        // 时长选择卡片
                        durationCard
                        
                        // 重复设置卡片
                        repeatCard
                        
                        // 提醒选项卡片
                        optionsCard
                        
                        // 删除按钮
                        deleteButton
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .frame(width: 450, height: 700)
    }
    
    // 复用 AddTimerView 的卡片组件...
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("基本信息", systemImage: "textformat")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("标题")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("例如：喝水、休息", text: $title)
                        .font(AppFonts.body)
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
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("描述（可选）")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("添加详细说明...", text: $description)
                        .font(AppFonts.body)
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
    }
    
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("时长设置", systemImage: "clock")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.lg) {
                    TimePicker(
                        title: "小时",
                        value: $hours,
                        range: 0..<24
                    )
                    
                    TimePicker(
                        title: "分钟",
                        value: $minutes,
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
    }
    
    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("重复设置", systemImage: "repeat")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                FrequencySelector(selection: $repeatFrequency)
                
                if repeatFrequency != .once {
                    Toggle("设置结束日期", isOn: $hasEndDate)
                        .font(AppFonts.subheadline)
                    
                    if hasEndDate {
                        DatePicker("", selection: $endDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                    .fill(AppColors.background)
                            )
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppShadows.md.color,
                    radius: AppShadows.md.radius,
                    x: AppShadows.md.x,
                    y: AppShadows.md.y
                )
        )
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
        timer.repeatFrequency = repeatFrequency
        timer.endDate = (repeatFrequency != .once && hasEndDate) ? endDate : nil
        timer.soundEnabled = soundEnabled
        timer.showFullscreenAlert = showFullscreenAlert

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
