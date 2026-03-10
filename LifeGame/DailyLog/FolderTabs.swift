import SwiftUI

// MARK: - Tabs Container (Generic)
struct FolderTabs<T: Hashable>: View {
    
    let tabs: [T]
    @Binding var selection: T
    let title: (T) -> String
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs, id: \.self) { tab in
                FolderTabButton(
                    title: title(tab),
                    isSelected: selection == tab
                ) {
                    selection = tab
                }
            }
        }
    }
}

// MARK: - Tab Button
struct FolderTabButton: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .foregroundStyle(
                    isSelected
                        ? (theme.isDark ? Color.black : Color.white)
                        : (theme.isDark ? Color.white.opacity(0.6) : Color(.secondaryLabel))
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected
                            ? (theme.isDark ? Color.white : Color(.label))
                            : (theme.isDark ? Color.white.opacity(0.08) : Color(.tertiarySystemFill))
                        )
                )
                .offset(y: isSelected ? 2 : 0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
