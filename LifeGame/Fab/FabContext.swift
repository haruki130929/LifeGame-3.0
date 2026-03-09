import Foundation

enum FeatureID: Hashable {
    case diary
    case calendar
    case wish
    case ledger
    case settings
}

enum FabContext {
    case home(timeSlot: TimeSlot, features: [FeatureID])
    case feature(FeatureID)
}
