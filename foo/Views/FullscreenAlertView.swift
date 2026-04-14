import SwiftUI

@available(macOS 14.0, *)
struct FullscreenAlertView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showSnoozeOptions = false
    @State private var ringScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 动态背景
            AnimatedBackground()

            // 内容
            contentView
        }
        .onAppear {
            withAnimation(AppAnimations.bouncy) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private var contentView: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            // 动态图标区域
            iconSection

            // 标题区域
            titleSection

            Spacer()

            // 按钮区域
            buttonSection
        }
        .foregroundColor(.white)
        .scaleEffect(scale)
        .opacity(opacity)
    }

    private var iconSection: some View {
        ZStack {
            // 外环动画
            ringView(index: 0)
            ringView(index: 1)
            ringView(index: 2)

            // 主图标
            mainIconView
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                ringScale = 1.5
            }
        }
    }

    private func ringView(index: Int) -> some View {
        Circle()
            .stroke(AppColors.primary.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
            .scaleEffect(ringScale + CGFloat(index) * 0.3)
            .opacity(2.0 - ringScale - CGFloat(index) * 0.3)
    }

    private var mainIconView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(
                    color: AppColors.primary.opacity(0.5),
                    radius: 30,
                    x: 0,
                    y: 10
                )

            Image(systemName: "bell.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var titleSection: some View {
        Group {
            if let timer = timerManager.completedTimer {
                VStack(spacing: AppSpacing.lg) {
                    Text(timer.title)
                        .font(AppFonts.title1)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    if !timer.timerDescription.isEmpty {
                        Text(timer.timerDescription)
                            .font(AppFonts.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }

                    Text("时间到了！")
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.warning)
                        .padding(.top, AppSpacing.md)
                }
            }
        }
    }

    private var buttonSection: some View {
        VStack(spacing: AppSpacing.lg) {
            if showSnoozeOptions {
                snoozeOptionsView
            } else {
                mainButtonsView
            }
        }
        .padding(.bottom, 60)
    }

    private var snoozeOptionsView: some View {
        VStack(spacing: AppSpacing.md) {
            Text("延迟提醒")
                .font(AppFonts.headline)
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: AppSpacing.lg) {
                SnoozeButton(minutes: 5) { snooze(minutes: 5) }
                SnoozeButton(minutes: 10) { snooze(minutes: 10) }
                SnoozeButton(minutes: 15) { snooze(minutes: 15) }
            }

            Button(action: {
                withAnimation(AppAnimations.spring) {
                    showSnoozeOptions = false
                }
            }) {
                Label("返回", systemImage: "arrow.backward")
                    .font(AppFonts.callout.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var mainButtonsView: some View {
        HStack(spacing: AppSpacing.xl) {
            // 延迟按钮
            ActionButton(
                title: "延迟",
                icon: "zzz",
                color: AppColors.warning,
                action: {
                    withAnimation(AppAnimations.spring) {
                        showSnoozeOptions = true
                    }
                }
            )

            // 完成按钮
            ActionButton(
                title: "完成",
                icon: "checkmark",
                color: AppColors.success,
                action: { dismiss() }
            )
        }
    }

    private func snooze(minutes: Int) {
        withAnimation(AppAnimations.normal) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            timerManager.snoozeTimer(minutes: minutes)
        }
    }

    private func dismiss() {
        withAnimation(AppAnimations.normal) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            timerManager.dismissAlert()
        }
    }
}

// MARK: - Animated Background

@available(macOS 14.0, *)
struct AnimatedBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // 基础渐变
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 动态光晕
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.3))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(
                            x: animate ? 100 : -100,
                            y: animate ? -100 : 100
                        )

                    Circle()
                        .fill(AppColors.primaryLight.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(
                            x: animate ? -150 : 150,
                            y: animate ? 150 : -150
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Action Button

@available(macOS 14.0, *)
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 80, height: 80)
                        .shadow(color: color.opacity(0.5), radius: 20, x: 0, y: 10)

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(AppFonts.callout.weight(.semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onHover { hovering in
            withAnimation(AppAnimations.fast) {
                isPressed = hovering
            }
        }
    }
}

// MARK: - Snooze Button

@available(macOS 14.0, *)
struct SnoozeButton: View {
    let minutes: Int
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Text("\(minutes)")
                    .font(AppFonts.title2.weight(.bold))
                Text("分钟")
                    .font(AppFonts.callout)
            }
            .foregroundColor(.white)
            .frame(width: 90, height: 90)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .fill(AppColors.warning.opacity(0.9))
                    .shadow(
                        color: AppColors.warning.opacity(0.4),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onHover { hovering in
            withAnimation(AppAnimations.fast) {
                isPressed = hovering
            }
        }
    }
}

// MARK: - Visual Effect Blur

@available(macOS 14.0, *)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
