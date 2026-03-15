import SwiftUI

/// 第一次打開 App 時顯示的新手引導
/// iPad: 2 頁（歡迎 → 準備）
/// iPhone: 3 頁（歡迎 → 裝置選擇 → 準備）
struct OnboardingView: View {

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @AppStorage("onboarding_completed_v1") private var completed = false

    @State private var currentPage = 0

    private let iPad = AppLayout.isIPad
    private var totalPages: Int { iPad ? 2 : 3 }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)

                    if !iPad {
                        deviceChoicePage.tag(1)
                    }

                    readyPage.tag(iPad ? 1 : 2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer()

                bottomBar
                    .padding(.bottom, iPad ? 60 : 50)
            }
            .frame(maxWidth: iPad ? 560 : .infinity)
        }
    }

    // MARK: - 背景

    private var background: some View {
        LinearGradient(
            colors: [
                theme.accentColor.opacity(0.15),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Page 1: 歡迎

    private var welcomePage: some View {
        VStack(spacing: iPad ? 32 : 24) {
            Spacer()

            Image(systemName: "gamecontroller.fill")
                .font(.system(size: iPad ? 96 : 72))
                .foregroundStyle(theme.accentColor)

            Text("歡迎來到 LifeGame")
                .font(.system(size: iPad ? 38 : 30, weight: .bold))
                .multilineTextAlignment(.center)

            Text("把生活變成一場遊戲\n用 HP、FP、MP 管理你的每一天")
                .font(.system(size: iPad ? 20 : 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Page 2 (iPhone only): 裝置選擇

    private var deviceChoicePage: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "ipad.and.iphone")
                .font(.system(size: 68))
                .foregroundStyle(theme.accentColor)

            Text("你的使用方式")
                .font(.system(size: 26, weight: .bold))

            Text("選擇最適合你的 iPhone 操作模式")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 14) {
                deviceChoiceButton(
                    icon: "ipad",
                    title: "我也有 iPad",
                    desc: "iPhone 使用簡略模式，快速翻頁操作",
                    isSelected: phoneModeStore.mode == .quick
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        phoneModeStore.mode = .quick
                    }
                }

                deviceChoiceButton(
                    icon: "iphone",
                    title: "只有 iPhone",
                    desc: "完整功能，與 iPad 版相同的操作體驗",
                    isSelected: phoneModeStore.mode == .full
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        phoneModeStore.mode = .full
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Last Page: 準備就緒

    private var readyPage: some View {
        VStack(spacing: iPad ? 32 : 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: iPad ? 88 : 68))
                .foregroundStyle(theme.accentColor)

            Text("準備好了！")
                .font(.system(size: iPad ? 38 : 30, weight: .bold))

            if iPad {
                Text("左上角開啟選單\n右上角開啟工具欄\n右下角「＋」新增功能")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text(phoneModeStore.mode == .quick
                     ? "左右滑動切換功能頁\n右上角開啟工具欄\n右下角「＋」快速操作\n可以在設定中自訂頁面"
                     : "左上角開啟選單\n右上角開啟工具欄\n右下角「＋」新增功能")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: iPad ? 28 : 24) {
            // 頁面指示器
            HStack(spacing: iPad ? 10 : 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? theme.accentColor : Color.gray.opacity(0.3))
                        .frame(
                            width: i == currentPage ? (iPad ? 30 : 24) : (iPad ? 10 : 8),
                            height: iPad ? 10 : 8
                        )
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            // 按鈕
            if currentPage < totalPages - 1 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("下一步")
                        .font(iPad ? .title3.bold() : .headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, iPad ? 18 : 16)
                        .background(theme.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 40)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        completed = true
                    }
                } label: {
                    Text("開始使用")
                        .font(iPad ? .title3.bold() : .headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, iPad ? 18 : 16)
                        .background(theme.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 40)
            }

            // 跳過
            if currentPage < totalPages - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        completed = true
                    }
                } label: {
                    Text("跳過")
                        .font(iPad ? .body : .subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 裝置選擇按鈕

    private func deviceChoiceButton(
        icon: String,
        title: String,
        desc: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isSelected ? .white : theme.accentColor)
                    .frame(width: 52, height: 52)
                    .background(isSelected ? theme.accentColor : theme.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.accentColor)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? theme.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
