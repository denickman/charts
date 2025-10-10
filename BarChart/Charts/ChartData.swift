//
//  SessionChartData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation

struct M_Session {
    let sittingStartedAt: Date
    let sittingOverall: Int
    let sittingOvertime: Int
    
    let exercisingStartedAt: Date
    let exercisingOverall: Int
    let exercisingOvertime: Int
}



struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let activityType: ActivityType
    let base: Double
    let extra: Double
    let timeLabel: String?
    
    var total: Double { base + extra }
}

enum ActivityType {
    case sitting, exercising
}

struct AxisConfig {
    let values: [Date]
    let labels: [String]
    let domain: ClosedRange<Date>
    let labelFormat: Date.FormatStyle
}
