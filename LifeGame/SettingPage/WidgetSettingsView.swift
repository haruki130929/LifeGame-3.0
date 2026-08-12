import SwiftUI
import WidgetKit

/// 桌面工具（Widget）設定頁
struct WidgetSettingsView: View {

    @State private var todoQuadrant: TodoQuadrant = .importantUrgent
    @State private var appearance: WidgetAppearanceOption = .system
    @State private var liveActivityOn: Bool = false
    @State private var todoLiveActivityOn: Bool = false

    private var sharedDefaults: UserDefaults { SharedConstants.sharedDefaults }
    private let quadrantKey = SharedConstants.Keys.widgetTodoQuadrant
    private let appearanceKey = SharedConstants.Keys.widgetAppearance

    init() {
        // 種入目前的開關狀態，避免 onAppear 時 false→true 誤觸 onChange 而重複 start()
        _liveActivityOn = State(initialValue: LiveActivityController.isEnabled)
        _todoLiveActivityOn = State(initialValue: TodoLiveActivityController.isEnabled)
    }

    var body: some View {
        Form {
            // MARK: 外觀
            Section {
                Picker(selection: $appearance) {
                    ForEach(WidgetAppearanceOption.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                } label: {
                    Label("深色／淺色", systemImage: "circle.lefthalf.filled")
                }
            } header: {
                Text("外觀")
            } footer: {
                Text("「跟隨系統」會跟著手機的深色／淺色；也可以把桌面工具固定成淺色或深色。")
            }

            // MARK: 即時動態（Live Activity）
            Section {
                Toggle(isOn: $liveActivityOn) {
                    Label("在鎖定畫面顯示今日狀態", systemImage: "bolt.horizontal.circle")
                }
                Toggle(isOn: $todoLiveActivityOn) {
                    Label("在靈動島／鎖定畫面顯示待辦", systemImage: "checklist")
                }
            } header: {
                Text("即時動態")
            } footer: {
                Text("「今日狀態」即時顯示 HP／FP／MP;「待辦」會顯示最近要到期的一筆，靈動島長按展開、或鎖定畫面可直接按「完成」打勾、自動換下一筆。跨日後系統會自動淡出。第一次開啟時系統可能會詢問是否允許「即時動態」。")
            }

            // MARK: 待辦小工具
            Section {
                Picker(selection: $todoQuadrant) {
                    ForEach(TodoQuadrant.allCases) { q in
                        Text(q.title).tag(q)
                    }
                } label: {
                    Label("顯示象限", systemImage: "list.bullet.clipboard")
                }
            } header: {
                Text("待辦小工具")
            } footer: {
                Text("「待辦」小工具只會顯示這個象限裡未完成的待辦，點一下即可完成、並同步回 App。")
            }

            // MARK: 可用的小工具
            Section("可用的小工具") {
                widgetRow(icon: "heart.text.square", title: String(localized: "今日狀態"),
                          desc: String(localized: "一眼看今天的 HP / FP / MP"))
                widgetRow(icon: "checklist", title: String(localized: "待辦"),
                          desc: String(localized: "列出待辦、點一下打勾完成"))
            }

            // MARK: 如何加到桌面
            Section {
                howToRow(1, String(localized: "長按桌面空白處，直到圖示開始晃動"))
                howToRow(2, String(localized: "點左上角的「＋」"))
                howToRow(3, String(localized: "搜尋「LifeGame」，選擇小工具加入"))
            } header: {
                Text("如何加到桌面")
            }

            // MARK: 重新整理
            Section {
                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label("立即重新整理桌面工具", systemImage: "arrow.clockwise")
                }
            } footer: {
                Text("資料變動時小工具會自動更新；如果一時沒更新，可以手動重新整理。")
            }
        }
        .navigationTitle("桌面工具")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .onChange(of: todoQuadrant) { _, newValue in
            sharedDefaults.set(newValue.rawValue, forKey: quadrantKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: appearance) { _, newValue in
            sharedDefaults.set(newValue.rawValue, forKey: appearanceKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: liveActivityOn) { _, on in
            if on { LiveActivityController.start() } else { LiveActivityController.stop() }
        }
        .onChange(of: todoLiveActivityOn) { _, on in
            if on { TodoLiveActivityController.start() } else { TodoLiveActivityController.stop() }
        }
    }

    // MARK: - Rows

    private func widgetRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 28)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func howToRow(_ step: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(step)")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.secondary.opacity(0.15)))
            Text(text).font(.subheadline)
        }
    }

    // MARK: - Persistence（寫進 App Group，供 Widget 讀取）

    private func load() {
        if sharedDefaults.object(forKey: quadrantKey) != nil {
            todoQuadrant = TodoQuadrant(rawValue: sharedDefaults.integer(forKey: quadrantKey)) ?? .importantUrgent
        }
        if sharedDefaults.object(forKey: appearanceKey) != nil {
            appearance = WidgetAppearanceOption(rawValue: sharedDefaults.integer(forKey: appearanceKey)) ?? .system
        }
        // liveActivityOn 已在 init() 種入，不在這裡指派以免誤觸 onChange
    }
}

/// App 端的外觀選項（rawValue 與 widget 端 WidgetAppearance 一致）
enum WidgetAppearanceOption: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .system: return String(localized: "跟隨系統")
        case .light:  return String(localized: "淺色")
        case .dark:   return String(localized: "深色")
        }
    }
}
