import SwiftUI

struct DailyRecordPage: View {
    @ObservedObject var store: DailyRecordStore
    
    @State private var showNew = false
    
    var body: some View {
        List {
            Section {
                Button {
                    showNew = true
                } label: {
                    Label("新增今天的紀錄", systemImage: "plus")
                }
            }
            
            Section("最近紀錄") {
                ForEach(store.allSorted()) { r in
                    NavigationLink {
                        DailyRecordEditorView(store: store, date: r.date)
                    } label: {
                        DailyRecordRow(record: r)
                    }
                }
            }
        }
        .navigationTitle("每日紀錄")
        .sheet(isPresented: $showNew) {
            NavigationStack {
                DailyRecordEditorView(store: store, date: Date())
            }
        }
    }
}

private struct DailyRecordRow: View {
    let record: DailyRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            
            HStack(spacing: 12) {
                Text("情緒 \(record.mood)")
                Text("焦慮 \(record.anxiety)")
                Text("專注 \(record.focus)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
