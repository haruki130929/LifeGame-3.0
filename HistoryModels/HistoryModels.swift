// File: History/HistoryModels.swift
import SwiftUI
import Foundation

enum DayDifficulty: String, Codable {
    case easy
    case medium
    case hard
    
    var score: Int {
        switch self {
        case .easy: return 70
        case .medium: return 50
        case .hard: return 30
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var title: String {
        switch self {
        case .easy: return "輕鬆"
        case .medium: return "中等"
        case .hard: return "有點吃力"
        }
    }
}

struct DayRecord: Identifiable, Codable, Hashable {
    var id: String { dateKey }
    let dateKey: String        // "yyyy-MM-dd"
    let hp: Int
    let fp: Int
    let mp: Int
    let median: Int
    let difficulty: DayDifficulty
    let score: Int
    
    static func make(date: Date, hp: Int, fp: Int, mp: Int) -> DayRecord {
        let m = medianOf3(hp, fp, mp)
        let diff: DayDifficulty
        if m >= 70 { diff = .easy }
        else if m >= 50 { diff = .medium }
        else { diff = .hard }
        
        return DayRecord(
            dateKey: dateKeyString(date),
            hp: hp,
            fp: fp,
            mp: mp,
            median: m,
            difficulty: diff,
            score: diff.score
        )
    }
}
