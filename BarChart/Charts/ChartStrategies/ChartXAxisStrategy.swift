//
//  ChartStrategies.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

//
//  ChartStrategies.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation
import SwiftUI

// MARK: - Simplified Protocols
protocol AxisStrategy {
    func getAxisConfiguration(for data: [ChartData]) -> AxisConfig
    func calculateBarPosition(for data: ChartData) -> Date
    var barWidth: Double { get }
}


// MARK: - Simplified Axis Strategies
class DayAxisStrategy: AxisStrategy {
    private let calendar = Calendar.current
    let barWidth: Double = 14.0
    
    func getAxisConfiguration(for data: [ChartData]) -> AxisConfig {
        let uniqueDates = Array(Set(data.map { $0.date })).sorted()
        let labels = data.compactMap { $0.timeLabel }.uniqued()
        
        let today = calendar.startOfDay(for: Date())
        let domain = today...calendar.date(byAdding: .day, value: 1, to: today)!
        
        return AxisConfig(
            values: uniqueDates,
            labels: labels,
            domain: domain,
            labelFormat: .dateTime.hour(.defaultDigits(amPM: .abbreviated))
        )
    }
    
    func calculateBarPosition(for data: ChartData) -> Date {
        let offset: TimeInterval = data.activityType == .sitting ? -3600 : 3600
        return data.date.addingTimeInterval(offset)
    }
}

class ThreeDaysAxisStrategy: AxisStrategy {
    private let calendar = Calendar.current
    let barWidth: Double = 4.0
    
    func getAxisConfiguration(for data: [ChartData]) -> AxisConfig {
        let uniqueDates = Array(Set(data.map { $0.date })).sorted()
        
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let domain = threeDaysAgo...today
        
        let labels = uniqueDates.map { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
        
        return AxisConfig(
            values: uniqueDates,
            labels: labels,
            domain: domain,
            labelFormat: .dateTime.weekday(.abbreviated)
        )
    }
    
    func calculateBarPosition(for data: ChartData) -> Date {
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: data.date) ?? data.date
    }
}


// MARK: - Utilities
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        Array(Set(self))
    }
}
