import SwiftUI

struct SchedulePlannerView: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    
    var body: some View {
        HStack(spacing: 0) {
            DayRingView(blocks: scheduleStore.blocks)
                .frame(maxWidth: .infinity)
            
            Divider()
            
            DayTimelineView(hourlyTitles: $scheduleStore.hourlyTitles)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle("行程規劃")
    }
}
