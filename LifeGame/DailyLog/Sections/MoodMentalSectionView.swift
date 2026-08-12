import SwiftUI

struct MoodMentalSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = String(localized: "情緒與心理狀態")

    var body: some View {
        Section(header) {
            ScoreSliderRow(title: String(localized: "整體情緒分數"), value: $entry.overallMoodScore)
            ScoreSliderRow(title: String(localized: "焦慮程度"), value: $entry.anxietyScore)
        }
    }
}
