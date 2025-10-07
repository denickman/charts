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
    
    // Helper methods
    func createDateRange(startOffset: Int, endOffset: Int = 1) -> ClosedRange<Date> {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: startOffset, to: calendar.startOfDay(for: now))!
        let end = calendar.date(byAdding: .day, value: endOffset, to: calendar.startOfDay(for: now))!
        return start...end
    }
    
    func generateHourlyAxisValues(hours: [Int]) -> [Date] {
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        guard let startOfDay = calendar.date(from: components) else { return [] }
        
        return hours.compactMap {
            calendar.date(bySettingHour: $0, minute: 0, second: 0, of: startOfDay)
        }
    }
    
    func generateDailyAxisValues(dayRange: ClosedRange<Int>) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        return dayRange.compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
}

// MARK: - One Day
class DayXAxisStrategy: BaseAxisStrategy {
    override var xAxisValues: [Date] {
        generateHourlyAxisValues(hours: ChartConfig.DataRanges.dayHours)
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        createDateRange(startOffset: 0)
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.hour(.defaultDigits(amPM: .abbreviated))
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
}

// MARK: - 1 Week
class WeekXAxisStrategy: BaseAxisStrategy {
    override var xAxisValues: [Date] {
        generateDailyAxisValues(dayRange: ChartConfig.DataRanges.weekRange)
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        createDateRange(startOffset: ChartConfig.DateOffsets.week)
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.weekday(.abbreviated)
    }
    
    override func centerDate(for date: Date) -> Date {
        calendar.date(bySettingHour: ChartConfig.DateOffsets.dayCenterHour, minute: 0, second: 0, of: date) ?? date
    }
    
    override var dynamicTimeOffset: TimeInterval {
        ChartConfig.Time.secondsInHour * ChartConfig.TimeOffsets.weekHours
    }
}

// MARK: - 15 Days
class HalfMonthXAxisStrategy: BaseAxisStrategy {
    override var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        let fifteenDaysAgo = calendar.date(
            byAdding: .day,
            value: ChartConfig.DateOffsets.halfOfMonth,
            to: today
        )!
        
        return (0..<15).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: fifteenDaysAgo)!
            return dayOffset % 3 == 0 ? date : nil // Each 3 days
        }
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        let today = calendar.startOfDay(for: Date())
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: ChartConfig.DateOffsets.halfOfMonth, to: today)!
        return fifteenDaysAgo...today
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.day().month(.abbreviated)
    }
    
    override func centerDate(for date: Date) -> Date {
        calendar.date(bySettingHour: ChartConfig.DateOffsets.dayCenterHour, minute: 0, second: 0, of: date) ?? date
    }
    
    override var dynamicTimeOffset: TimeInterval {
        ChartConfig.Time.secondsInHour * ChartConfig.TimeOffsets.weekHours
    }
    
    override var dynamicBarWidth: Double {
        ChartConfig.Bar.minWidth
    }
}

// MARK: - 1 Month
class MonthXAxisStrategy: BaseAxisStrategy {
    override var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(
            byAdding: .day,
            value: ChartConfig.DateOffsets.month,
            to: today
        )!
        
        return (0..<ChartConfig.DataRanges.monthWeeks).compactMap { weekIndex in
            let daysOffset = weekIndex * ChartConfig.DataRanges.weekDaysInterval
            let weekStart = calendar.date(byAdding: .day, value: daysOffset, to: thirtyDaysAgo)!
            return weekStart <= today ? weekStart : nil
        }
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        createDateRange(startOffset: ChartConfig.DateOffsets.month)
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.day()
    }
    
    override var dynamicTimeOffset: TimeInterval {
        ChartConfig.Time.secondsInHour * ChartConfig.TimeOffsets.monthHours
    }
    
    override var dynamicBarWidth: Double {
        ChartConfig.Bar.minWidth
    }
}

// MARK: - Month-based strategies
class MonthBasedAxisStrategy: BaseAxisStrategy {
    let monthsCount: Int
    
    init(monthsCount: Int) {
        self.monthsCount = monthsCount
        super.init()
    }
    
    override var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return []
        }
        
        return (0..<monthsCount).compactMap { monthOffset in
            calendar.date(byAdding: .month, value: -monthOffset, to: startOfCurrentMonth)
        }.sorted()
    }
}

// MARK: - Half Year
class HalfYearXAxisStrategy: MonthBasedAxisStrategy {
    init() {
        super.init(monthsCount: ChartConfig.Time.monthsInHalfYear)
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        guard let start = xAxisValues.first, let end = xAxisValues.last else {
            return super.xAxisDomain
        }
        
        let startWithPadding = calendar.date(
            byAdding: .day,
            value: -ChartConfig.DataRanges.weekDaysInterval,
            to: start
        )!
        let endWithPadding = calendar.date(byAdding: .month, value: 1, to: end)!
        return startWithPadding...endWithPadding
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.month(.abbreviated)
    }
    
    override func centerDate(for date: Date) -> Date {
        calendar.date(byAdding: .day, value: Int(ChartConfig.Time.daysInWeek / 2), to: date) ?? date
    }
    
    override var dynamicTimeOffset: TimeInterval {
        Double(ChartConfig.TimeOffsets.halfYearDays) *
        ChartConfig.Time.secondsInHour *
        ChartConfig.Time.hoursInDay
    }
    
    override var dynamicBarWidth: Double {
        ChartConfig.Bar.minWidth
    }
}

// MARK: - 1 Year
class YearXAxisStrategy: MonthBasedAxisStrategy {
    init() {
        super.init(monthsCount: ChartConfig.Time.monthsInYear)
    }
    
    override var xAxisDomain: ClosedRange<Date> {
        guard let start = xAxisValues.first, let end = xAxisValues.last else {
            return super.xAxisDomain
        }
        
        let endWithPadding = calendar.date(byAdding: .month, value: 1, to: end)!
        return start...endWithPadding
    }
    
    override var xAxisLabelFormat: Date.FormatStyle {
        .dateTime.month(.narrow)
    }
    
    override func centerDate(for date: Date) -> Date {
        calendar.date(byAdding: .day, value: ChartConfig.DateOffsets.yearCenterDays, to: date) ?? date
    }
    
    override var dynamicTimeOffset: TimeInterval {
        ChartConfig.Time.secondsInHour *
        ChartConfig.Time.hoursInDay *
        ChartConfig.DateOffsets.yearTimeOffsetDays
    }
    
    override var dynamicBarWidth: Double {
        ChartConfig.Bar.defaultWidth / ChartConfig.Bar.WidthAdjustments.yearWidthMultiplier
    }
}
