import SwiftUI

struct WeekReviewView: View {
    @ObservedObject var store: WeekReviewStore
    
    @State private var selectedWeekKey: String = ""
    
    @State private var didText: String = ""
    @State private var resultText: String = ""
    @State private var issuesText: String = ""
    @State private var planText: String = ""
    
    @State private var q1: String = ""
    @State private var q2: String = ""
    @State private var q3: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerBar
                
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let gap: CGFloat = 12
                    let cellWidth = (totalWidth - gap) / 2
                    let cellHeight = max(220, cellWidth * 0.62)
                    
                    Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                        GridRow {
                            quadCard(title: String(localized: "實際執行內容"), text: $didText)
                                .frame(width: cellWidth, height: cellHeight)
                            quadCard(title: String(localized: "辦到 / 沒辦到（先寫辦到）"), text: $resultText)
                                .frame(width: cellWidth, height: cellHeight)
                        }
                        GridRow {
                            quadCard(title: String(localized: "煩惱 / 課題"), text: $issuesText)
                                .frame(width: cellWidth, height: cellHeight)
                            quadCard(title: String(localized: "修正路線的行動計劃"), text: $planText)
                                .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                }
                .frame(height: 520)
                
                threeQuestions
            }
            .padding(16)
        }
        .navigationTitle("回顧筆記")
        .onAppear {
            load(store.currentWeekKey())
        }
    }
    
    private var headerBar: some View {
        HStack(spacing: 10) {
            Button("本週") { load(store.currentWeekKey()) }
                .buttonStyle(.bordered)
            
            Button("上週") { load(store.lastWeekKey()) }
                .buttonStyle(.bordered)
            
            Spacer()
            
            Text(selectedWeekKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("儲存") { save() }
                .buttonStyle(.borderedProminent)
        }
    }
    
    private func quadCard(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            TextEditor(text: text)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var threeQuestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("活用回顧的三個問題").font(.headline)
            
            questionRow(String(localized: "該怎麼做才能更加接近自己的夢想與目標？"), text: $q1)
            questionRow(String(localized: "如果還能再加以改善，是哪一點可以改善？"), text: $q2)
            questionRow(String(localized: "如果想把這個經驗活用在下次行動，該怎麼做才好？"), text: $q3)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func questionRow(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundStyle(.secondary)
            TextField("簡短寫一句也可以", text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private func load(_ weekKey: String) {
        selectedWeekKey = weekKey
        
        if let r = store.review(for: weekKey) {
            didText = r.did
            resultText = r.result
            issuesText = r.issues
            planText = r.plan
            q1 = r.q1
            q2 = r.q2
            q3 = r.q3
        } else {
            didText = ""
            resultText = ""
            issuesText = ""
            planText = ""
            q1 = ""
            q2 = ""
            q3 = ""
        }
    }
    
    private func save() {
        let r = WeekReview(
            weekKey: selectedWeekKey.isEmpty ? store.currentWeekKey() : selectedWeekKey,
            did: didText,
            result: resultText,
            issues: issuesText,
            plan: planText,
            q1: q1,
            q2: q2,
            q3: q3,
            updatedAt: Date()
        )
        store.upsert(r)
    }
}
