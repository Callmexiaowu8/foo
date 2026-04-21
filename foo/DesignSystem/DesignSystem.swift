import SwiftUI

// MARK: - 配色方案
@available(macOS 14.0, *)
enum AppColors {
    static let primary = Color(hex: "0A84FF")
    static let primaryLight = Color(hex: "5AC8FA")
    static let primaryDark = Color(hex: "0077E6")

    // 渐变色组
    static let accentBlue = Color(hex: "0A84FF")
    static let accentCyan = Color(hex: "5AC8FA")
    static let accentBlueDarker = Color(hex: "0077E6")
    static let accentCyanDarker = Color(hex: "4AB8EA")

    static let success = Color(hex: "30D15A")
    static let successLight = Color(hex: "34C759")
    static let warning = Color(hex: "FF9F0A")
    static let warningLight = Color(hex: "FF9500")
    static let error = Color(hex: "FF453A")
    static let errorLight = Color(hex: "FF3B30")
    static let info = Color(hex: "5856D6")
    
    // 状态颜色（统一使用）
    static let activeGreen = Color(hex: "34C759")
    static let pausedOrange = Color(hex: "FF9500")
    static let inactiveGray = Color(hex: "8E8E93")

    static let background = Color(hex: "F5F7FA")
    static let cardBackground = Color.white
    static let divider = Color(hex: "E5E9EF")
    static let textPrimary = Color(hex: "1C1C1E")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "C7C7CC")
    
    // 菜单栏背景色
    static let menuBarBackgroundTop = Color(hex: "E8F4FD")
    static let menuBarBackgroundBottom = Color(hex: "F0F8FF")

    static let gradientStart = Color(hex: "0A84FF")
    static let gradientEnd = Color(hex: "5AC8FA")

    static let darkBackground = Color(hex: "1C1C1E")
    static let darkCardBackground = Color(hex: "2C2C2E")
    static let darkDivider = Color(hex: "3A3A3C")
}

// MARK: - 字体规范
@available(macOS 14.0, *)
enum AppFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    static let timerDisplay = Font.system(size: 64, weight: .light, design: .monospaced)
    static let timerDisplaySmall = Font.system(size: 48, weight: .light, design: .monospaced)
    static let timerDisplayMini = Font.system(size: 32, weight: .regular, design: .monospaced)
}

// MARK: - 间距规范
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - 圆角规范
enum AppCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - 阴影规范
@available(macOS 14.0, *)
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

@available(macOS 14.0, *)
enum AppShadows {
    static let sm = ShadowStyle(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    static let md = ShadowStyle(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let lg = ShadowStyle(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    static let glow = ShadowStyle(color: AppColors.primary.opacity(0.3), radius: 20, x: 0, y: 0)
}

// MARK: - 动画规范
@available(macOS 14.0, *)
enum AppAnimations {
    static let fast = Animation.easeOut(duration: 0.15)
    static let normal = Animation.easeOut(duration: 0.25)
    static let slow = Animation.easeOut(duration: 0.4)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - 扩展
@available(macOS 14.0, *)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 按钮尺寸规范
enum AppButtonSize {
    static let large: CGFloat = 44
    static let medium: CGFloat = 36
    static let small: CGFloat = 32
    static let iconOnly: CGFloat = 32
}

// MARK: - 按钮圆角规范
enum AppButtonCornerRadius {
    static let pill: CGFloat = 9999
    static let large: CGFloat = 12
    static let medium: CGFloat = 10
    static let small: CGFloat = 8
}

// MARK: - View 扩展
@available(macOS 14.0, *)
extension View {
    func cardStyle() -> some View {
        self
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.xl)
            .shadow(
                color: AppShadows.md.color,
                radius: AppShadows.md.radius,
                x: AppShadows.md.x,
                y: AppShadows.md.y
            )
    }

    func glassStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(AppCornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }

    func primaryButtonStyle(isHovered: Bool = false, isPressed: Bool = false) -> some View {
        let scale = isPressed ? 0.97 : (isHovered ? 1.02 : 1.0)
        let shadowRadius: CGFloat = isHovered ? 12 : 8
        let shadowOpacity: Double = isHovered ? 0.4 : 0.3

        return self
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AppButtonCornerRadius.medium)
            .shadow(
                color: AppColors.primary.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: isHovered ? 6 : 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppButtonCornerRadius.medium)
                    .stroke(Color.white.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1)
            )
            .scaleEffect(scale)
    }

    func secondaryButtonStyle(isHovered: Bool = false) -> some View {
        return self
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                isHovered ? AppColors.primary.opacity(0.08) : AppColors.cardBackground
            )
            .foregroundColor(isHovered ? AppColors.primaryDark : AppColors.primary)
            .cornerRadius(AppButtonCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppButtonCornerRadius.medium)
                    .stroke(AppColors.primary.opacity(isHovered ? 0.5 : 0.3), lineWidth: isHovered ? 1.5 : 1)
            )
    }

    func actionButtonStyle(color: Color, isHovered: Bool = false, isPressed: Bool = false) -> some View {
        let scale = isPressed ? 0.95 : (isHovered ? 1.05 : 1.0)
        let bgOpacity = isHovered ? 0.18 : 0.1
        let borderOpacity = isHovered ? 0.4 : 0.2
        let shadowOpacity = isHovered ? 0.25 : 0.0

        return self
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppButtonCornerRadius.small)
                    .fill(color.opacity(bgOpacity))
            )
            .foregroundColor(isHovered ? color : color)
            .cornerRadius(AppButtonCornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppButtonCornerRadius.small)
                    .stroke(color.opacity(borderOpacity), lineWidth: isHovered ? 1.5 : 1)
            )
            .shadow(
                color: color.opacity(shadowOpacity),
                radius: isHovered ? 6 : 0,
                x: 0,
                y: isHovered ? 3 : 0
            )
            .scaleEffect(scale)
    }

    func iconButtonStyle(color: Color, size: CGFloat = AppButtonSize.iconOnly, isHovered: Bool = false, isPressed: Bool = false) -> some View {
        let scale = isPressed ? 0.92 : (isHovered ? 1.1 : 1.0)
        let bgOpacity = isHovered ? 0.2 : 0.1
        let borderOpacity = isHovered ? 0.4 : 0.25
        let shadowOpacity = isHovered ? 0.3 : 0.0

        return self
            .font(.system(size: size * 0.375, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: AppButtonCornerRadius.small)
                    .fill(color.opacity(bgOpacity))
            )
            .cornerRadius(AppButtonCornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppButtonCornerRadius.small)
                    .stroke(color.opacity(borderOpacity), lineWidth: isHovered ? 1.5 : 1)
            )
            .shadow(
                color: color.opacity(shadowOpacity),
                radius: isHovered ? 6 : 0,
                x: 0,
                y: isHovered ? 3 : 0
            )
            .scaleEffect(scale)
    }

    func compactButtonStyle(color: Color, isHovered: Bool = false) -> some View {
        return self
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(isHovered ? color : AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHovered ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }

    func pillButtonStyle(color: Color, isHovered: Bool = false, isPressed: Bool = false) -> some View {
        let scale = isPressed ? 0.96 : (isHovered ? 1.03 : 1.0)

        return self
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(isHovered ? 0.15 : 0.1))
            )
            .foregroundColor(color)
            .overlay(
                Capsule()
                    .stroke(color.opacity(isHovered ? 0.35 : 0.2), lineWidth: isHovered ? 1.5 : 1)
            )
            .scaleEffect(scale)
    }
}
