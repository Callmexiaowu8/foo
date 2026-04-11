import SwiftUI

@available(macOS 14.0, *)
struct AutoDismissSelector: View {
    @Binding var seconds: Int
    let label: String

    private let options: [Int] = [5, 10, 15, 20, 30, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 20)

                Text(label)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: AppSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    AutoDismissButton(
                        seconds: option,
                        isSelected: seconds == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            seconds = option
                        }
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

@available(macOS 14.0, *)
struct AutoDismissButton: View {
    let seconds: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    private var displayText: String {
        if seconds >= 60 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds)s"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .frame(minWidth: 36)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? AppColors.primary : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
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
