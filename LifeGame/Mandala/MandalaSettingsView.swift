import SwiftUI

struct MandalaSettingsView: View {

    @StateObject private var store = MandalaStore()

    // 顏色設定
    @State private var goalColor: Color = .clear
    @State private var themeColor: Color = .clear
    @State private var actionColor: Color = .clear
    @State private var useCustomGoalColor = false
    @State private var useCustomThemeColor = false
    @State private var useCustomActionColor = false

    // 匯出
    @State private var showExportSuccess = false

    // 清空確認
    @State private var showClearConfirm = false

    // 刪除圖表確認
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            colorSection
            exportSection
            dataSection
        }
        .navigationTitle("曼陀羅圖表設定")
        .onAppear { loadColors() }
        .alert("已儲存到相簿", isPresented: $showExportSuccess) {
            Button("好") {}
        }
        .alert("確定要清空目前圖表的所有內容？", isPresented: $showClearConfirm) {
            Button("清空", role: .destructive) {
                store.reset()
            }
            Button("取消", role: .cancel) {}
        }
        .alert("確定要刪除目前的圖表？", isPresented: $showDeleteConfirm) {
            Button("刪除", role: .destructive) {
                store.deleteDocument(at: store.currentIndex)
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - 背景顏色

    private var colorSection: some View {
        Section {
            Toggle("自訂目標格顏色", isOn: $useCustomGoalColor)
            if useCustomGoalColor {
                ColorPicker("目標格顏色", selection: $goalColor, supportsOpacity: false)
                    .onChange(of: goalColor) { _, newColor in
                        applyColorToGoal(newColor)
                    }
            }

            Toggle("自訂主題格顏色", isOn: $useCustomThemeColor)
            if useCustomThemeColor {
                ColorPicker("主題格顏色", selection: $themeColor, supportsOpacity: false)
                    .onChange(of: themeColor) { _, newColor in
                        applyColorToThemes(newColor)
                    }
            }

            Toggle("自訂行動格顏色", isOn: $useCustomActionColor)
            if useCustomActionColor {
                ColorPicker("行動格顏色", selection: $actionColor, supportsOpacity: false)
                    .onChange(of: actionColor) { _, newColor in
                        applyColorToActions(newColor)
                    }
            }
        } header: {
            Text("背景顏色")
        } footer: {
            Text("自訂各類格子的背景顏色，關閉後恢復預設")
        }
    }

    // MARK: - 匯出

    private var exportSection: some View {
        Section("匯出") {
            Button {
                exportAsImage()
            } label: {
                Label("匯出為圖片", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - 資料

    private var dataSection: some View {
        Section("資料管理") {
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                Label("清空目前圖表", systemImage: "trash")
            }

            if store.documents.count > 1 {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("刪除目前圖表", systemImage: "xmark.circle")
                }
            }
        }
    }

    // MARK: - Color Logic

    private let goalPosition = (4, 4)
    private let themePositions: [(Int, Int)] = [
        (3, 3), (3, 4), (3, 5),
        (4, 3),         (4, 5),
        (5, 3), (5, 4), (5, 5),
    ]

    private func loadColors() {
        if let hex = store.cellColor(row: 4, col: 4) {
            goalColor = Color(hex: hex)
            useCustomGoalColor = true
        }
        if let hex = store.cellColor(row: 3, col: 3) {
            themeColor = Color(hex: hex)
            useCustomThemeColor = true
        }
        // 取第一個行動格的顏色作為代表
        if let hex = store.cellColor(row: 0, col: 0) {
            actionColor = Color(hex: hex)
            useCustomActionColor = true
        }
    }

    private func applyColorToGoal(_ color: Color) {
        guard let hex = color.toHex() else { return }
        store.setCellColor(row: 4, col: 4, hex: hex)
    }

    private func applyColorToThemes(_ color: Color) {
        guard let hex = color.toHex() else { return }
        for pos in themePositions {
            store.setCellColor(row: pos.0, col: pos.1, hex: hex)
        }
        // 外圍區塊中心也套用
        for blockRow in 0..<3 {
            for blockCol in 0..<3 {
                if blockRow == 1 && blockCol == 1 { continue }
                store.setCellColor(row: blockRow * 3 + 1, col: blockCol * 3 + 1, hex: hex)
            }
        }
    }

    private func applyColorToActions(_ color: Color) {
        guard let hex = color.toHex() else { return }
        let offsets: [(Int, Int)] = [
            (0, 0), (0, 1), (0, 2),
            (1, 0),         (1, 2),
            (2, 0), (2, 1), (2, 2),
        ]
        for blockRow in 0..<3 {
            for blockCol in 0..<3 {
                if blockRow == 1 && blockCol == 1 { continue }
                for off in offsets {
                    store.setCellColor(row: blockRow * 3 + off.0, col: blockCol * 3 + off.1, hex: hex)
                }
            }
        }
    }

    // MARK: - 匯出圖片

    @MainActor
    private func exportAsImage() {
        let dummyEditMode = Binding.constant(false)
        let chartView = MandalaChartView(store: store, isEditMode: dummyEditMode)
            .frame(width: 900, height: 900)
            .background(Color(UIColor.systemGroupedBackground))

        let renderer = ImageRenderer(content: chartView)
        renderer.scale = UIScreen.main.scale

        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showExportSuccess = true
        }
    }
}
