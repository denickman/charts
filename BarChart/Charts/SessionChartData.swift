//
//  SessionChartData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

//
//  SessionChartData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation

struct M_Session {
    let sittingOverall, sittingOvertime: Int
    let exercisingOverall, exercisingOvertime: Int
    let createdAt: Date
}

struct AggregatedData: Identifiable {
    enum ActivityType: String {
        case sitting = "Sitting", exercising = "Exercising"
    }
    
    let id = UUID()
    let periodCenterDate: Date
    let activityType: ActivityType
    let baseMinutes, extraMinutes: Double
}
