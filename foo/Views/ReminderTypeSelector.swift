import SwiftUI

@available(macOS 14.0, *)
struct ReminderTypeSelector: View {
    @Binding var selectedType: ReminderType

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 20)

                Text("提醒方式")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: AppSpacing.sm) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    ReminderTypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

@available(macOS 14.0, *)
struct ReminderTypeButton: View {
    let type: ReminderType
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 16, weight: .medium))

                Text(type.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.primary : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
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
