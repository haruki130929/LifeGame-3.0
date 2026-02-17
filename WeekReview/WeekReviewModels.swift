import Foundation

struct WeekReview: Codable {
    var weekKey: String
    
    var did: String
    var result: String
    var issues: String
    var plan: String
    
    var q1: String
    var q2: String
    var q3: String
    
    var updatedAt: Date
}
