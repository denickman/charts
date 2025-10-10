//
//  SessionChartData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation

import Foundation

struct M_Session {
    let sittingOverall: Int
    let sittingOvertime: Int
    let exercisingOverall: Int
    let exercisingOvertime: Int
    let createdAt: Date
}

struct AggregatedData: Identifiable {
    enum ActivityType: String {
        case sitting = "Sitting"
        case exercising = "Exercising"
    }
    
    let id = UUID()
    let date: Date  // Center of the period (segment or day)
    let activityType: ActivityType
    let base: Double
    let extra: Double
}
