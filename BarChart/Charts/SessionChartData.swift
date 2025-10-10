//
//  SessionChartData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation

//
//  SessionChartData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation

struct SessionData: Identifiable {
    let id = UUID()
    let sittingDate: Date
    let exercisingDate: Date
    let sittingBase: Double
    let sittingOvertime: Double
    let exercisingBase: Double
    let exercisingExtra: Double
}

struct AggregatedData: Identifiable {
    
    enum ActivityType: String {
        case sitting = "Sitting"
        case exercising = "Exercising"
    }
    
    let id = UUID()
    let date: Date
    let activityType: ActivityType
    let base: Double
    let extra: Double
    let intervalLabel: String? // New property for interval labels
}

