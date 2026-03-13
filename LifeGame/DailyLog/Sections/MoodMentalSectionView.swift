import SwiftUI

struct MoodMentalSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = "情緒與心理狀態"

    var body: some View {
        Section(header) {
            ScoreSliderRow(title: "整體情緒分數", value: $entry.overallMoodScore)
            ScoreSliderRow(title: "焦慮程度", value: $entry.anxietyScore)
        }
    }
}
