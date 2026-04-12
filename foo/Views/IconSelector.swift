import SwiftUI

@available(macOS 14.0, *)
struct IconSelector: View {
    @Binding var selectedIcon: String?
    @State private var isExpanded = false
    @State private var hoverScale = 1.0

    var body: some View {
        Button(action: { isExpanded = true }) {
            ZStack {
                Circle()
                    .fill(selectedIcon == nil ? AppColors.primary.opacity(0.1) : AppColors.primary.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: selectedIcon ?? "face.smiling")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
                    .scaleEffect(hoverScale)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoverScale = hovering ? 1.1 : 1.0
            }
        }
        .sheet(isPresented: $isExpanded) {
            IconPickerModal(selectedIcon: $selectedIcon, isPresented: $isExpanded)
        }
    }
}

@available(macOS 14.0, *)
struct IconPickerModal: View {
    @Binding var selectedIcon: String?
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    struct IconItem: Identifiable {
        let id = UUID()
        let icon: String
        let colorHex: String
    }

    private let iconCategories: [(String, String, [IconItem])] = [
        ("时间", "clock", [
            IconItem(icon: "timer", colorHex: "#007AFF"),
            IconItem(icon: "alarm", colorHex: "#FF9500"),
            IconItem(icon: "clock", colorHex: "#AF52DE"),
            IconItem(icon: "hourglass", colorHex: "#8E8E93")
        ]),
        ("日期", "calendar", [
            IconItem(icon: "calendar", colorHex: "#FF3B30"),
            IconItem(icon: "calendar.badge.plus", colorHex: "#34C759")
        ]),
        ("自然", "leaf", [
            IconItem(icon: "sun.max", colorHex: "#FFCC00"),
            IconItem(icon: "moon", colorHex: "#5856D6"),
            IconItem(icon: "leaf", colorHex: "#34C759"),
            IconItem(icon: "flame", colorHex: "#FF9500"),
            IconItem(icon: "drop", colorHex: "#007AFF")
        ]),
        ("生活", "house", [
            IconItem(icon: "house", colorHex: "#007AFF"),
            IconItem(icon: "fork.knife", colorHex: "#8E8E93"),
            IconItem(icon: "cup.and.saucer", colorHex: "#8E8E93"),
            IconItem(icon: "car", colorHex: "#FF3B30")
        ]),
        ("健康", "heart", [
            IconItem(icon: "heart", colorHex: "#FF3B30"),
            IconItem(icon: "brain", colorHex: "#FF2D55"),
            IconItem(icon: "figure.walk", colorHex: "#34C759")
        ]),
        ("工作", "briefcase", [
            IconItem(icon: "briefcase", colorHex: "#8E8E93"),
            IconItem(icon: "book", colorHex: "#007AFF"),
            IconItem(icon: "pencil", colorHex: "#FF9500")
        ]),
        ("娱乐", "music.note", [
            IconItem(icon: "music.note", colorHex: "#AF52DE"),
            IconItem(icon: "film", colorHex: "#FF3B30"),
            IconItem(icon: "tv", colorHex: "#000000"),
            IconItem(icon: "gamecontroller", colorHex: "#8E8E93")
        ]),
        ("状态", "bolt", [
            IconItem(icon: "bolt", colorHex: "#FFCC00"),
            IconItem(icon: "battery.100", colorHex: "#34C759"),
            IconItem(icon: "wifi", colorHex: "#007AFF")
        ])
    ]

    private var filteredCategories: [(String, String, [IconItem])] {
        if searchText.isEmpty {
            return iconCategories
        }
        return iconCategories.compactMap { category, catIcon, icons in
            let filtered = icons.filter { $0.icon.localizedCaseInsensitiveContains(searchText) }
            return filtered.isEmpty ? nil : (category, catIcon, filtered)
        }
    }

    private var allIcons: [IconItem] {
        if let category = selectedCategory {
            return iconCategories.first(where: { $0.0 == category })?.2 ?? []
        }
        if searchText.isEmpty {
            return iconCategories.flatMap { $0.2 }
        }
        return iconCategories.flatMap { $0.2 }.filter { $0.icon.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            HStack(spacing: 0) {
                categorySidebar
                Divider()
                mainContent
            }
        }
        .frame(width: 600, height: 420)
    }

    private var headerBar: some View {
        HStack {
            Text("选择图标")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("搜索图标...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 160)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(6)

            Button("完成") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var categorySidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("分类")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 6)

            categoryButton(nil, "square.grid.2x2", "全部", selectedCategory == nil)

            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(iconCategories, id: \.0) { category, catIcon, _ in
                        categoryButton(category, catIcon, category, selectedCategory == category)
                    }
                }
            }

            Spacer()
        }
        .frame(width: 100)
        .background(Color(.controlBackgroundColor))
    }

    private func categoryButton(_ category: String?, _ iconName: String, _ title: String, _ isSelected: Bool) -> some View {
        Button(action: { selectedCategory = category }) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 11))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 12))
                Spacer()
            }
            .foregroundColor(isSelected ? .accentColor : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .cornerRadius(5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var mainContent: some View {
        ScrollView {
            if searchText.isEmpty && selectedCategory == nil {
                categoriesView
            } else {
                allIconsGrid
            }
        }
    }

    private var categoriesView: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(filteredCategories, id: \.0) { category, catIcon, icons in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: catIcon)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(category)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                        ForEach(icons, id: \.icon) { item in
                            iconButton(item)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var allIconsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
            ForEach(allIcons, id: \.icon) { item in
                iconButton(item)
            }
        }
        .padding(12)
    }

    private func iconButton(_ item: IconItem) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.12)) {
                if selectedIcon == item.icon {
                    selectedIcon = nil
                } else {
                    selectedIcon = item.icon
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedIcon == item.icon ? Color.accentColor.opacity(0.15) : Color.clear)
                    .frame(width: 52, height: 52)

                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedIcon == item.icon ? .accentColor : Color(hex: item.colorHex))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedIcon == item.icon ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
