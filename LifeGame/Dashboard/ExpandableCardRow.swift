import SwiftUI

/// iPhone 手風琴列：同一個外框內，點擊 header 往下展開功能內容
struct ExpandableCardRow: View {
    let cardType: CardType
    @Binding var expandedCardType: CardType?
    @Binding var ringSelectedID: UUID?

    @EnvironmentObject private var theme: ThemeStore

    private var isExpanded: Bool {
        expandedCardType == cardType
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        VStack(spacing: 0) {
            // MARK: - Header（始終可見）
            headerRow

            // MARK: - 展開內容（同一個框內，直接顯示功能內容）
            if isExpanded {
                Divider()
                    .padding(.top, 8)

                if let featureID = cardType.featureID {
                    NavigationLink(value: featureID) {
                        expandedContent
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    expandedContent
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if theme.isDark {
                shape.fill(.thinMaterial)
            } else {
                shape.fill(Color.white)
            }
        }
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                theme.isDark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.10),
                lineWidth: 1
            )
        )
        .shadow(
            color: theme.isDark ? .black.opacity(0.3) : .black.opacity(0.08),
            radius: theme.isDark ? 10 : 8,
            x: 0,
            y: theme.isDark ? 6 : 3
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                expandedCardType = isExpanded ? nil : cardType
            }
        }
        .accessibilityLabel(cardType.title)
        .accessibilityHint(isExpanded ? "雙擊以收合" : "雙擊以展開")
        // 上下滑動：下拉展開、上推收起
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let vertical = value.translation.height
                    guard abs(value.translation.width) < abs(vertical) else { return }

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        if vertical > 40 && !isExpanded {
                            expandedCardType = cardType
                        } else if vertical < -40 && isExpanded {
                            expandedCardType = nil
                        }
                    }
                }
        )
    }

    // MARK: - Header Row
    private var headerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: cardType.icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(cardType.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? -180 : 0))
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.82),
                    value: isExpanded
                )
        }
    }

    // MARK: - 展開的原始內容（直接用 CardFactory，避免重複維護）

    @ViewBuilder
    private var expandedContent: some View {
        CardFactory(cardType: cardType, ringSelectedID: $ringSelectedID)
    }
}
