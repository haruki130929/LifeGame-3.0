import SwiftUI

struct ObservationSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = String(localized: "特別觀察到的事情")

    var body: some View {
        Section(header) {
            TextEditor(text: $entry.specialObservation)
                .frame(minHeight: 120)

            DailyLogPhotosSection(photos: $entry.photos)
        }
    }
}
