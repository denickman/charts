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


// MARK: - Base Protocols
protocol ChartAxisStrategy {
    var xAxisValues: [Date] { get }
    var xAxisDomain: ClosedRange<Date> { get }
    var xAxisLabelFormat: Date.FormatStyle { get }
    var dynamicTimeOffset: TimeInterval { get }
    var dynamicBarWidth: Double { get }
    
    func centerDate(for date: Date) -> Date
    func getXAxisLabels(from aggregatedData: [AggregatedData]) -> [String]
    func getXAxisValues(from aggregatedData: [AggregatedData]) -> [Date] // Добавлен этот метод
}

// MARK: - Base Axis Strategy
class BaseAxisStrategy: ChartAxisStrategy {
    let calendar = Calendar.current
    
    var xAxisValues: [Date] { [] }
    var xAxisDomain: ClosedRange<Date> { Date()...Date() }
    var xAxisLabelFormat: Date.FormatStyle { .dateTime }
    var dynamicTimeOffset: TimeInterval { 0 }
    var dynamicBarWidth: Double { ChartConfig.Bar.defaultWidth }
    
    func centerDate(for date: Date) -> Date { date }
    func getXAxisLabels(from aggregatedData: [AggregatedData]) -> [String] { [] }
    func getXAxisValues(from aggregatedData: [AggregatedData]) -> [Date] { [] } // Добавлена реализация по умолчанию
    
    // Helper methods
    func createDateRange(startOffset: Int, endOffset: Int = 1) -> ClosedRange<Date> {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: startOffset, to: calendar.startOfDay(for: now))!
        let end = calendar.date(byAdding: .day, value: endOffset, to: calendar.startOfDay(for: now))!
        return start...end
    }
}

// MARK: - One Day
class DayXAxisStrategy: BaseAxisStrategy {
    override var xAxisDomain: ClosedRange<Date> {
        createDateRange(startOffset: 0)
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.hour(.defaultDigits(amPM: .abbreviated))
    }
    
    override var dynamicTimeOffset: TimeInterval {
        ChartConfig.Time.secondsInHour * 1 // 1 hour offset for day period
    }
    
    override func getXAxisLabels(from aggregatedData: [AggregatedData]) -> [String] {
        // Extract unique interval labels from aggregated data
        let uniqueLabels = Set(aggregatedData.compactMap { $0.intervalLabel })
        return Array(uniqueLabels).sorted()
    }
    
    override func getXAxisValues(from aggregatedData: [AggregatedData]) -> [Date] {
        // Get unique dates from aggregated data and sort them
        let uniqueDates = Array(Set(aggregatedData.map { $0.date })).sorted()
        return uniqueDates
    }
}

// MARK: - Three Days
class ThreeDaysXAxisStrategy: BaseAxisStrategy {
    override var xAxisValues: [Date] {
        generateDailyAxisValues(dayRange: ChartConfig.DataRanges.threeDaysRange)
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        createDateRange(startOffset: ChartConfig.DateOffsets.threeDays)
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.weekday(.abbreviated)
    }
    
    override var dynamicBarWidth: Double {
        ChartConfig.Bar.minWidth
    }
    
    override var dynamicTimeOffset: TimeInterval {
        ChartConfig.Time.secondsInHour * 12 // 12 hours offset for three days period
    }
    
    override func centerDate(for date: Date) -> Date {
        calendar.date(bySettingHour: ChartConfig.DateOffsets.dayCenterHour, minute: 0, second: 0, of: date) ?? date
    }
    
    override func getXAxisLabels(from aggregatedData: [AggregatedData]) -> [String] {
        // For three days, use weekday names
        let uniqueDates = Array(Set(aggregatedData.map { $0.date })).sorted()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return uniqueDates.map { formatter.string(from: $0) }
    }
    
    override func getXAxisValues(from aggregatedData: [AggregatedData]) -> [Date] {
        // Get unique dates from aggregated data and sort them
        let uniqueDates = Array(Set(aggregatedData.map { $0.date })).sorted()
        return uniqueDates
    }
    
    // Helper method for generating daily values
    private func generateDailyAxisValues(dayRange: ClosedRange<Int>) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        return dayRange.compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
}
