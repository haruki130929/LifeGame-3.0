// File: Core/Stat.swift
import Foundation

struct Stat {
    var current: Int
    var max: Int
    
    mutating func add(_ delta: Int) {
        current = Swift.min(self.max, Swift.max(0, current + delta))
    }
}
