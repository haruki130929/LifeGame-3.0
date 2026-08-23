import SwiftUI
import MessageUI

// MARK: - 內文
//
// ⚠️ 要改文字就改這裡，底下的 View 不用動。
// 內容取自 `docs/LifeGamer創作理念.md`，只做了分段與小標；改動時兩邊要一起更新。
//
// 這段刻意只有繁體中文：它是一封信，不是介面字串。翻成三語會變成三封語氣不同的信，
// 而且每次改一個字就要重翻。頁面的標題與按鈕仍然走 `L10n`，三語照常。

enum DeveloperNote {

    static let title = "開發者的話"
    static let subtitle = "讓生活像一場遊戲，但不是為了贏"

    /// 署名與寫作時間。改內文時記得一起更新日期。
    static let signature = "はるき"
    static let dateline = "寫於 2026 年 8 月・v1.20"

    static let passages: [Passage] = [
        Passage(
            heading: "今天的你，還剩多少力氣？",
            body: """
            大部分的生產力工具都在問：「今天完成了多少？」

            LifeGamer 想問的是另一個問題：「今天的你，還剩多少力氣？」
            """
        ),
        Passage(
            heading: "不是效率系統，是生活工具",
            body: """
            這個作品源自一種很日常、卻經常被忽略的困難：有時候，我們不是不知道該做什麼，而是沒有足夠的體力、專注力或情緒空間去開始。當一個人已經很累，再多的提醒、未完成數字與連續打卡，未必能帶來行動，反而可能成為另一種壓力。

            因此，我想做的不是一套把生活塞得更滿的效率系統，而是一個幫助人辨認狀態、安排負荷，也允許自己停下來的生活工具。
            """
        ),
        Passage(
            heading: "HP、FP、MP 不是成績，是資源",
            body: """
            LifeGamer 借用角色扮演遊戲的語言，以 HP、FP、MP 分別呈現體力、專注力與心情。這些數值不是成績，也不是用來判斷一個人今天夠不夠努力；它們更像是一天之中可以分配的資源。

            當 HP 只剩二十點，重要的不是想辦法假裝自己還有一百點，而是誠實地決定：這二十點要留給什麼，又有哪些事情可以等到明天。
            """
        ),
        Passage(
            heading: "遊戲化是界線，不是獎勵",
            body: """
            LifeGamer 的遊戲化不是獎勵機制，而是一種界線。它沒有要求使用者不斷累積經驗值、維持連續紀錄，或把每一天都變成必須通關的任務。

            數值每天重新開始，是因為人的狀態本來就會變動；昨天做得到的事，今天未必做得到，而這不等於退步。比起催促人做得更多，我更希望它能提醒人：不要做超過自己可以負荷的事情。
            """
        ),
        Passage(
            heading: "理念決定了功能的樣子",
            body: """
            LifeGamer 先記錄狀態，再記錄任務；每日紀錄使用具體、可觀察的描述，並把「忘記紀錄」當成正式答案，而不是逼人為了填滿表格而猜測。當話語一時出不來，溝通板提供另一種表達方式；當行動卡住，動力筆記把方法拆成足夠小的第一步。

            這些功能不是附加在效率工具旁邊的補充品，而是作品的中心：困難不應該被藏起來，自我照顧也不該等到所有正事做完之後才開始。
            """
        ),
        Passage(
            heading: "保留趣味，不製造競爭感",
            body: """
            資料夾般的面板、會回應操作的動畫，以及由使用者選擇的日本傳統色，讓原本抽象而沉重的自我管理變得具體、柔和，也帶有個人的樣子。

            色彩不只是裝飾，而是一種選擇權：這不是系統替你定義的人生畫面，而是你可以慢慢調整成自己喜歡的空間。
            """
        ),
        Passage(
            heading: "隱私是設計的一部分",
            body: """
            生活紀錄涉及非常私密的內容，所以隱私不是藏在設定頁裡的一行說明，而是設計的一部分。LifeGamer 以本機使用為出發點，不用追蹤與廣告交換便利；若選擇開啟 iCloud，同步也只透過 Apple 的私人資料庫進行。

            工具可以協助理解生活，但不應該因此取得生活的所有權。
            """
        ),
        Passage(
            heading: "它想做的事情比較小，也比較誠實",
            body: """
            LifeGamer 不承諾讓每個人變得更自律、更高效，或每天都比昨天進步。它想做的事情比較小，也比較誠實：讓看不見的狀態變得可見，讓說不出口的需要仍有表達方式，讓卡住的時候還找得到下一個足夠小的動作。

            如果人生是一場遊戲，我希望 LifeGamer 提醒人的不是如何贏過別人，而是如何在有限的點數裡，好好照顧自己的角色，並按照自己的節奏繼續走下去。
            """
        ),
    ]

    struct Passage: Identifiable {
        let heading: String
        let body: String
        var id: String { heading }
    }
}

// MARK: - 畫面

/// 設定 →「開發者的話」。
struct DeveloperNoteView: View {

    @EnvironmentObject private var theme: ThemeStore

    @State private var showFeedbackMail = false
    @State private var showMailUnavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerBlock

                ForEach(DeveloperNote.passages) { passage in
                    passageBlock(passage)
                }

                signatureBlock

                feedbackButton
            }
            // 兩側留白比 Form 寬一點：這是一段要讀完的文字，行太長會讀不下去。
            .padding(.horizontal, AppLayout.isIPad ? 40 : 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(L10n.Settings.developerNote)
        .navigationBarTitleDisplayMode(.inline)
        // 設定頁被 push 進來時，上一層的「＋」會浮回來擋住內文與底部按鈕。
        .hidesFab()
        .sheet(isPresented: $showFeedbackMail) {
            FeedbackMailView()
        }
        .alert("無法傳送郵件", isPresented: $showMailUnavailable) {
            Button("複製信箱地址") {
                UIPasteboard.general.string = "harukiyang122@gmail.com"
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("你的裝置尚未設定郵件帳號。\n請手動寄信至 harukiyang122@gmail.com")
        }
    }
}

// MARK: - Blocks
private extension DeveloperNoteView {

    var headerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(theme.accentColor)

            Text(DeveloperNote.title)
                .font(.largeTitle.bold())

            Text(DeveloperNote.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    func passageBlock(_ passage: DeveloperNote.Passage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(passage.heading)
                .font(.headline)
                .foregroundStyle(theme.accentColor)

            Text(passage.body)
                .font(.body)
                // 內文行距放寬：整頁都是長段落，預設行距讀起來太擠。
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var signatureBlock: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Divider()
                .padding(.bottom, 12)

            Text(DeveloperNote.signature)
                .font(.title3.weight(.semibold))

            Text(DeveloperNote.dateline)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var feedbackButton: some View {
        Button {
            if MFMailComposeViewController.canSendMail() {
                showFeedbackMail = true
            } else {
                showMailUnavailable = true
            }
        } label: {
            Label(L10n.Settings.tellMeWhatYouThink, systemImage: "envelope")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(theme.accentColor)
    }
}
