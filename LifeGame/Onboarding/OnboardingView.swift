import SwiftUI
import AuthenticationServices

/// 第一次打開 App 時顯示的新手引導
struct OnboardingView: View {

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @EnvironmentObject private var slotNameStore: TimeSlotNameStore
    @EnvironmentObject private var appleSignIn: AppleSignInManager
    @Environment(StorageCoordinator.self) private var coordinator: StorageCoordinator?
    @Environment(StorageConfiguration.self) private var storageConfig: StorageConfiguration?
    @Binding var completed: Bool

    @State private var currentPage = 0

    private let iPad = AppLayout.isIPad
    private var totalPages: Int { iPad ? 4 : 5 }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)

                    roleChoicePage.tag(1)

                    if !iPad {
                        deviceChoicePage.tag(2)
                    }

                    iCloudPage.tag(iPad ? 2 : 3)

                    readyPage.tag(iPad ? 3 : 4)
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

    // MARK: - Page 2: 角色選擇

    private var roleChoicePage: some View {
        VStack(spacing: iPad ? 32 : 28) {
            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: iPad ? 80 : 68))
                .foregroundStyle(theme.accentColor)

            Text("你的身份")
                .font(.system(size: iPad ? 34 : 26, weight: .bold))

            Text("我們會根據你的身份\n調整介面用語")
                .font(.system(size: iPad ? 18 : 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 14) {
                deviceChoiceButton(
                    icon: "graduationcap.fill",
                    title: String(localized: "學生"),
                    desc: String(localized: "上一堂課扣 HP、FP"),
                    isSelected: slotNameStore.role == .student
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        slotNameStore.role = .student
                    }
                }

                deviceChoiceButton(
                    icon: "briefcase.fill",
                    title: String(localized: "上班族"),
                    desc: String(localized: "工作一小時扣 HP、FP"),
                    isSelected: slotNameStore.role == .worker
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        slotNameStore.role = .worker
                    }
                }
            }
            .padding(.horizontal, 32)

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
                    title: String(localized: "我也有 iPad"),
                    desc: String(localized: "iPhone 使用簡略模式，快速翻頁操作"),
                    isSelected: phoneModeStore.mode == .quick
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        phoneModeStore.mode = .quick
                    }
                }

                deviceChoiceButton(
                    icon: "iphone",
                    title: String(localized: "只有 iPhone"),
                    desc: String(localized: "完整功能，與 iPad 版相同的操作體驗"),
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

    // MARK: - Apple ID 登入

    private var iCloudPage: some View {
        VStack(spacing: iPad ? 32 : 24) {
            Spacer()

            if appleSignIn.isSignedIn {
                // 已登入狀態
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: iPad ? 80 : 68))
                    .foregroundStyle(.green)

                Text("已登入")
                    .font(.system(size: iPad ? 34 : 26, weight: .bold))

                Text(appleSignIn.displayName)
                    .font(.system(size: iPad ? 20 : 17))
                    .foregroundStyle(.secondary)

                Text("你的資料會自動同步到 iCloud\n刪除 App 重新安裝也不會遺失")
                    .font(.system(size: iPad ? 18 : 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // 未登入狀態
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: iPad ? 80 : 68))
                    .foregroundStyle(theme.accentColor)

                Text("登入 Apple ID")
                    .font(.system(size: iPad ? 34 : 26, weight: .bold))

                Text("登入後資料會自動備份到 iCloud\n刪除 App 重新安裝也不會遺失")
                    .font(.system(size: iPad ? 18 : 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    appleSignIn.handleSignInResult(result)
                    if appleSignIn.isSignedIn {
                        // 登入成功 → 自動開啟 iCloud 同步
                        coordinator?.scheduleSwitch(to: .iCloud)
                    }
                }
                .signInWithAppleButtonStyle(theme.isDark ? .white : .black)
                .frame(height: 50)
                .frame(maxWidth: 280)
                .padding(.top, 8)
            }

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

            // 教學提示
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.caption)
                Text("隨時到 設定 → 使用教學 查看操作說明")
                    .font(.caption)
            }
            .foregroundStyle(.tertiary)
            .padding(.top, 8)

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
                    applySettingsAndComplete()
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
                    applySettingsAndComplete()
                } label: {
                    Text("跳過")
                        .font(iPad ? .body : .subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 完成 Onboarding

    private func applySettingsAndComplete() {
        withAnimation(.easeInOut(duration: 0.35)) {
            completed = true
            OnboardingTracker.markCompleted()
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

// MARK: - Onboarding 狀態追蹤（UserDefaults）
// ⚠️ 必須用 UserDefaults，因為 MyApp.init() 讀取時 StorageCoordinator 尚未初始化

enum OnboardingTracker {
    private static let udKey = "onboarding_completed_v1"

    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: udKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: udKey)
    }
}
