import SwiftUI

// MARK: - 教學資料模型

struct TutorialItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let steps: [TutorialStep]
    let tip: String?
}

struct TutorialStep {
    let text: String
}

// MARK: - 教學主頁

struct TutorialView: View {
    @EnvironmentObject private var coachMarkStore: CoachMarkStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore

    var body: some View {
        Form {
            conceptSection
            featureSection
            tipsSection
        }
        .navigationTitle(L10n.Tutorial.title)
    }

    // MARK: - 基本概念

    private var conceptSection: some View {
        Section {
            ForEach(TutorialData.concepts) { item in
                NavigationLink {
                    TutorialDetailView(item: item)
                } label: {
                    tutorialRow(item)
                }
            }
        } header: {
            Label(L10n.Tutorial.concepts, systemImage: "book")
        }
    }

    // MARK: - 功能介紹

    private var featureSection: some View {
        Section {
            ForEach(TutorialData.features) { item in
                NavigationLink {
                    TutorialDetailView(item: item)
                } label: {
                    tutorialRow(item)
                }
            }
        } header: {
            Label(L10n.Tutorial.features, systemImage: "star")
        }
    }

    // MARK: - 操作技巧

    private var tipsSection: some View {
        Section {
            ForEach(TutorialData.tips) { item in
                NavigationLink {
                    TutorialDetailView(item: item)
                } label: {
                    tutorialRow(item)
                }
            }

            // 重新播放新手引導
            Button {
                coachMarkStore.restart(isQuickMode: phoneModeStore.mode == .quick)
            } label: {
                Label(L10n.Tutorial.replayCoachMark, systemImage: "arrow.counterclockwise")
            }
        } header: {
            Label(L10n.Tutorial.operationTips, systemImage: "lightbulb")
        }
    }

    // MARK: - Row

    private func tutorialRow(_ item: TutorialItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(item.color)
                .frame(width: 28, height: 28)

            Text(item.title)
                .font(.body)
        }
    }
}

// MARK: - 教學內容資料

enum TutorialData {

    // MARK: 基本概念

    static let concepts: [TutorialItem] = [
        TutorialItem(
            icon: "heart.fill",
            title: "HP / FP / MP 是什麼",
            color: .red,
            steps: [
                TutorialStep(text: "LifeGame 把你的生活遊戲化，用三種數值來追蹤你的狀態。"),
                TutorialStep(text: "HP（體力值）：代表你的身體狀態。上課、工作會消耗體力，休息可以恢復。"),
                TutorialStep(text: "FP（疲勞值）：代表你的疲勞程度。數值越高代表越累，需要適當休息。"),
                TutorialStep(text: "MP（精神值）：代表你的精神能量。學習新事物、做有創意的事會消耗精神。"),
                TutorialStep(text: "你可以在主畫面上方看到這三個數值，隨時掌握自己的狀態。"),
            ],
            tip: "每天結算時，系統會根據你的活動自動調整數值。"
        ),
        TutorialItem(
            icon: "sun.max.fill",
            title: "每日結算怎麼運作",
            color: .orange,
            steps: [
                TutorialStep(text: "每天結束時，你可以進行「每日結算」來回顧今天的表現。"),
                TutorialStep(text: "結算會根據你今天完成的任務、記錄的心情、時間安排來計算分數。"),
                TutorialStep(text: "完成越多待辦事項、保持好心情、合理安排時間，分數越高。"),
                TutorialStep(text: "結算後，HP/FP/MP 會重置，準備迎接新的一天。"),
            ],
            tip: "如果結算錯誤，可以使用「撤銷結算」功能回復。"
        ),
        TutorialItem(
            icon: "shield.fill",
            title: "裝備系統",
            color: .purple,
            steps: [
                TutorialStep(text: "裝備系統讓你為自己的角色配備各種道具，增加能力值上限。"),
                TutorialStep(text: "每件裝備有不同的重量，角色可以攜帶的總重量有限。"),
                TutorialStep(text: "選擇適合你目前需求的裝備組合，平衡 HP、FP、MP 的加成。"),
            ],
            tip: "裝備不會消失，可以隨時更換。"
        ),
    ]

    // MARK: 功能介紹

    static let features: [TutorialItem] = [
        TutorialItem(
            icon: "calendar",
            title: L10n.Title.calendar,
            color: .blue,
            steps: [
                TutorialStep(text: "行事曆讓你管理日程和行程，以月曆方式顯示。"),
                TutorialStep(text: "點擊日期可以查看當天的行程，彩色橫條代表跨天的行程。"),
                TutorialStep(text: "按右下角「＋」→「新增行程」來建立新的行程。"),
            ],
            tip: "可以在設定中選擇一週的起始日（週日或週一）。"
        ),
        TutorialItem(
            icon: "list.bullet.clipboard",
            title: L10n.Title.todoQuadrant,
            color: .green,
            steps: [
                TutorialStep(text: "待辦四象限用「重要」和「緊急」兩個維度來分類你的任務。"),
                TutorialStep(text: "第一象限：重要又緊急 → 立刻做"),
                TutorialStep(text: "第二象限：重要不緊急 → 安排時間做"),
                TutorialStep(text: "第三象限：緊急不重要 → 委託別人或快速處理"),
                TutorialStep(text: "第四象限：不重要不緊急 → 考慮是否需要做"),
                TutorialStep(text: "完成任務後點擊打勾，會影響每日結算分數。"),
            ],
            tip: "優先處理第一象限，多花時間在第二象限，減少第三、四象限的事。"
        ),
        TutorialItem(
            icon: "clock",
            title: L10n.Title.tomorrowRing,
            color: .cyan,
            steps: [
                TutorialStep(text: "時間圓環幫你規劃一天的時間分配，以環形圖呈現。"),
                TutorialStep(text: "每個時段用不同顏色區分，可以看到時間的佔比。"),
                TutorialStep(text: "按「新增時段」來加入活動，按「快速接續」可以自動接在上一個時段之後。"),
                TutorialStep(text: "時間圓環會自動扣減 HP/FP/MP，不同活動消耗不同。"),
            ],
            tip: nil
        ),
        TutorialItem(
            icon: "square.and.pencil",
            title: L10n.Title.dailyLog,
            color: .indigo,
            steps: [
                TutorialStep(text: "每日紀錄讓你記錄當天的各種狀態和感受。"),
                TutorialStep(text: "包含：心情、焦慮程度、身體狀況、睡眠品質、專注度等。"),
                TutorialStep(text: "還可以附加照片，記錄生活中的重要時刻。"),
                TutorialStep(text: "長期記錄可以幫助你發現自己的狀態模式。"),
            ],
            tip: "可以在設定中自訂要顯示哪些問題模組。"
        ),
        TutorialItem(
            icon: "heart.text.square",
            title: L10n.Title.moodThermometer,
            color: .pink,
            steps: [
                TutorialStep(text: "心情溫度計讓你每小時記錄當下的心情（0-10 分）。"),
                TutorialStep(text: "可以看到一整天的心情變化趨勢圖。"),
                TutorialStep(text: "在 Watch App 上也可以快速記錄心情。"),
            ],
            tip: "開啟「每小時提醒」，系統會定時提醒你記錄心情。"
        ),
        TutorialItem(
            icon: "backpack",
            title: L10n.Title.bagRequired,
            color: .brown,
            steps: [
                TutorialStep(text: "整理書包幫你建立出門前的物品清單。"),
                TutorialStep(text: "可以設定哪些是「必帶」物品，確保不會忘記。"),
                TutorialStep(text: "每天出門前打勾確認，養成整理的好習慣。"),
            ],
            tip: nil
        ),
        TutorialItem(
            icon: "square.grid.3x3",
            title: L10n.Title.mandala,
            color: .teal,
            steps: [
                TutorialStep(text: "曼陀羅圖表是一種目標設定工具，用 9 宮格方式展開。"),
                TutorialStep(text: "中間放核心目標，周圍 8 格放達成核心目標所需的子目標。"),
                TutorialStep(text: "每個子目標又可以再展開 8 個具體行動項目。"),
            ],
            tip: "從核心目標開始，一層一層向外展開思考。"
        ),
        TutorialItem(
            icon: "calendar.badge.clock",
            title: L10n.Title.monthlyScore,
            color: .mint,
            steps: [
                TutorialStep(text: "本月結算以日曆方式顯示每天的結算分數。"),
                TutorialStep(text: "顏色深淺代表當天的表現，一眼就能看出整月的趨勢。"),
                TutorialStep(text: "點擊「統計」可以查看更詳細的數據分析。"),
            ],
            tip: nil
        ),
        TutorialItem(
            icon: "sparkles",
            title: "願望 & 記帳",
            color: .yellow,
            steps: [
                TutorialStep(text: "願望清單讓你記錄想要的東西，設定目標金額。"),
                TutorialStep(text: "記帳功能幫你追蹤收支，了解錢花到哪裡去了。"),
                TutorialStep(text: "搭配使用，可以為願望存錢，達成目標時標記「買了！」。"),
            ],
            tip: nil
        ),
    ]

    // MARK: 操作技巧

    static let tips: [TutorialItem] = [
        TutorialItem(
            icon: "plus.circle.fill",
            title: "FAB 選單",
            color: .blue,
            steps: [
                TutorialStep(text: "右下角的「＋」按鈕是 FAB（Floating Action Button），是你最常用的操作入口。"),
                TutorialStep(text: "iPad / 一般模式：點擊展開選單，再點功能名稱進入。"),
                TutorialStep(text: "iPhone 圓環模式：長按「＋」按鈕，手指滑向功能圖示放開即可。"),
                TutorialStep(text: "進入功能頁面後，FAB 會變成該功能的快捷操作（新增、編輯等）。"),
            ],
            tip: "可以在 設定 → 介面操作 中切換「選單」和「圓環」兩種操作方式。"
        ),
        TutorialItem(
            icon: "rectangle.on.rectangle",
            title: "簡略模式 vs 一般模式",
            color: .purple,
            steps: [
                TutorialStep(text: "iPhone 有兩種顯示模式可以選擇。"),
                TutorialStep(text: "一般模式：與 iPad 相同的完整功能，左側有選單按鈕。"),
                TutorialStep(text: "簡略模式：左右滑動切換功能頁面，更適合快速操作。"),
                TutorialStep(text: "可以在 設定 → 顯示模式 中切換。"),
            ],
            tip: "簡略模式下可以自訂要顯示哪些功能頁面。"
        ),
        TutorialItem(
            icon: "icloud.fill",
            title: "iCloud 同步 & 備份",
            color: .cyan,
            steps: [
                TutorialStep(text: "開啟 iCloud 同步後，資料會自動備份到雲端。"),
                TutorialStep(text: "即使刪除 App 重新安裝，資料也會自動恢復。"),
                TutorialStep(text: "同一個 Apple ID 登入的所有裝置都能同步資料。"),
                TutorialStep(text: "到 設定 → 儲存方式 可以查看和管理同步狀態。"),
            ],
            tip: "建議開啟 iCloud 同步，確保資料安全。"
        ),
    ]
}
