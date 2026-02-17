import SwiftUI

struct DayTimelineView: View {
    @Binding var hourlyTitles: [String]
    
    var body: some View {
        List {
            ForEach(0..<24, id: \.self) { h in
                HStack(spacing: 12) {
                    Text(String(format: "%02d:00", h))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 64, alignment: .leading)
                    
                    TextField("輸入行程", text: Binding(
                        get: { hourlyTitles[h] },
                        set: { hourlyTitles[h] = $0 }
                    ))
                    .textInputAutocapitalization(.never)
                }
            }
        }
    }
}
