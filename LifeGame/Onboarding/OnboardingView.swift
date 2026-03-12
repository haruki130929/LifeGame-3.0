import SwiftUI

/// 第一次打開 App 時顯示的新手引導
/// iPad: 3 頁（歡迎 → 功能 → 準備）
/// iPhone: 4 頁（歡迎 → 功能 → 裝置選擇 → 準備）
struct OnboardingView: View {

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @AppStorage("onboarding_completed_v1") private var completed = false

    @State private var currentPage = 0

    private let iPad = Layout.isIPad
    /// iPhone 多一頁「裝置選擇」
    private var totalPages: Int { iPad ? 3 : 4 }

    var body: some View {
        ZStack {
            // 背景
            background

            VStack(spacing: 0) {
                Spacer()

                // 內容頁
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)

                    if !iPad {
                        deviceChoicePage.tag(2)
                    }

                    readyPage.tag(iPad ? 2 : 3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer()

                // 底部：頁面指示器 + 按鈕
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
                .symbolEffect(.pulse, options: .repeating)

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

    // MARK: - Page 2: 功能導覽

    private var featuresPage: some View {
        VStack(spacing: iPad ? 36 : 28) {
            Spacer()

            Text("你的隨身工具箱")
                .font(.system(size: iPad ? 34 : 26, weight: .bold))

            if iPad {
                // iPad: 2×2 Grid
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)],
                    spacing: 20
                ) {
                    featureCard(icon: "calendar", color: .red, title: "行事曆", desc: "管理你的行程\n與重要日期")
                    featureCard(icon: "list.bullet.clipboard", color: .orange, title: "待辦四象限", desc: "用重要 × 緊急\n分類任務")
                    featureCard(icon: "clock", color: .blue, title: "時間圓環", desc: "視覺化規劃\n你的一天")
                    featureCard(icon: "face.smiling", color: .green, title: "心情追蹤", desc: "記錄每天的\n心情變化")
                }
                .padding(.horizontal, 24)
            } else {
                // iPhone: 垂直列表
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(icon: "calendar", color: .red, title: "行事曆", desc: "管理你的行程與重要日期")
                    featureRow(icon: "list.bullet.clipboard", color: .orange, title: "待辦四象限", desc: "用重要 × 緊急分類任務")
                    featureRow(icon: "clock", color: .blue, title: "時間圓環", desc: "視覺化規劃你的一天")
                    featureRow(icon: "face.smiling", color: .green, title: "心情追蹤", desc: "記錄每天的心情變化")
                }
                .padding(.horizontal, 36)
            }

            Spacer()
        }
    }

    // MARK: - Page 3 (iPhone only): 裝置選擇

    private var deviceChoicePage: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "ipad.and.iphone")
                .font(.system(size: 68))
                .foregroundStyle(theme.accentColor)
                .symbolEffect(.pulse, options: .repeating)

            Text("你的使用方式")
                .font(.system(size: 26, weight: .bold))

            Text("選擇最適合你的 iPhone 操作模式")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 14) {
                // 有 iPad → 簡略模式
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

                // 只有 iPhone → 一般模式
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
                .symbolEffect(.variableColor.iterative, options: .repeating)

            Text("準備好了！")
                .font(.system(size: iPad ? 38 : 30, weight: .bold))

            if iPad {
                Text("左上角開啟選單\n右下角「＋」新增功能\n長按切頁可以自訂內容")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text(phoneModeStore.mode == .quick
                     ? "左右滑動切換功能頁\n右下角「＋」快速操作\n可以在設定中自訂頁面"
                     : "左上角開啟選單\n右下角「＋」新增功能\n長按切頁可以自訂內容")
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

    // MARK: - iPhone: 功能列

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - iPad: 功能卡片（Grid 用）

    private func featureCard(icon: String, color: Color, title: String, desc: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(title)
                .font(.system(size: 18, weight: .semibold))

            Text(desc)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}
