//
//  ChartStrategies.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation
import SwiftUI

protocol ChartXAxisStrategy {
    var xAxisValues: [Date] { get }
    var xAxisDomain: ClosedRange<Date> { get }
    var xAxisLabelFormat: Date.FormatStyle { get }
    var dynamicTimeOffset: TimeInterval { get }
    var dynamicBarWidth: Double { get }
    
    func centerDate(for date: Date) -> Date
}

// MARK: - One Day
class DayXAxisStrategy: ChartXAxisStrategy {
    private let calendar = Calendar.current
    
    var xAxisValues: [Date] {
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        return SessionChartViewModel.Constants.DataRanges.dayHours.compactMap {
            calendar.date(bySettingHour: $0, minute: 0, second: 0, of: calendar.date(from: components)!)
        }
    }
    
    var xAxisDomain: ClosedRange<Date> {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return startOfDay...endOfDay
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
    }
    
    func centerDate(for date: Date) -> Date {
        return date
    }
    
    var dynamicTimeOffset: TimeInterval { 0 }
    
    var dynamicBarWidth: Double {
        return SessionChartViewModel.Constants.defaultBarWidth
    }
}

// MARK: - Three Days
class ThreeDaysXAxisStrategy: ChartXAxisStrategy {
    private let calendar = Calendar.current
    
    var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        return SessionChartViewModel.Constants.DataRanges.threeDaysRange.compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    var xAxisDomain: ClosedRange<Date> {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.threeDays, to: calendar.startOfDay(for: now))!
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return start...end
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        return .dateTime.weekday(.abbreviated)
    }
    
    func centerDate(for date: Date) -> Date {
        return date
    }
    
    var dynamicTimeOffset: TimeInterval { 0 }
    
    var dynamicBarWidth: Double {
        return SessionChartViewModel.Constants.minBarWidth
    }
}

// MARK: - 1 Week
class WeekXAxisStrategy: ChartXAxisStrategy {
    private let calendar = Calendar.current
    
    var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        return SessionChartViewModel.Constants.DataRanges.weekRange.compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    var xAxisDomain: ClosedRange<Date> {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.week, to: calendar.startOfDay(for: now))!
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return start...end
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        return .dateTime.weekday(.abbreviated)
    }
    
    func centerDate(for date: Date) -> Date {
        return calendar.date(bySettingHour: SessionChartViewModel.Constants.DateOffsets.dayCenterHour, minute: 0, second: 0, of: date) ?? date
    }
    
    var dynamicTimeOffset: TimeInterval {
        return SessionChartViewModel.Constants.Time.secondsInHour * SessionChartViewModel.Constants.TimeOffsets.weekHours
    }
    
    var dynamicBarWidth: Double {
        return SessionChartViewModel.Constants.defaultBarWidth
    }
}

// MARK: - 1 Month
class MonthXAxisStrategy: ChartXAxisStrategy {
    private let calendar = Calendar.current
    
    var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.month, to: today)!
        
        var weekStarts: [Date] = []
        for i in 0..<SessionChartViewModel.Constants.DataRanges.monthWeeks {
            let daysOffset = i * SessionChartViewModel.Constants.DataRanges.weekDaysInterval
            let weekStart = calendar.date(byAdding: .day, value: daysOffset, to: thirtyDaysAgo)!
            if weekStart <= today {
                weekStarts.append(weekStart)
            }
        }
        return weekStarts
    }
    
    var xAxisDomain: ClosedRange<Date> {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.month, to: calendar.startOfDay(for: now))!
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return start...end
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        return .dateTime.day()
    }
    
    func centerDate(for date: Date) -> Date {
        return date
    }
    
    var dynamicTimeOffset: TimeInterval {
        return SessionChartViewModel.Constants.Time.secondsInHour * SessionChartViewModel.Constants.TimeOffsets.monthHours
    }
    
    var dynamicBarWidth: Double {
        return SessionChartViewModel.Constants.minBarWidth
    }
}

// MARK: - Half Year
class HalfYearXAxisStrategy: ChartXAxisStrategy {
    private let calendar = Calendar.current
    
    var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var monthStarts: [Date] = []
        for i in 0..<SessionChartViewModel.Constants.Time.monthsInHalfYear {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                monthStarts.append(monthStart)
            }
        }
        return monthStarts.sorted()
    }
    
    var xAxisDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        guard let start = xAxisValues.first,
              let end = xAxisValues.last else {
            return now...calendar.date(byAdding: .month, value: 1, to: now)!
        }
        
        let startWithPadding = calendar.date(byAdding: .day, value: -SessionChartViewModel.Constants.DataRanges.weekDaysInterval, to: start)!
        let endWithPadding = calendar.date(byAdding: .month, value: 1, to: end)!
        return startWithPadding...endWithPadding
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        return .dateTime.month(.abbreviated)
    }
    
    func centerDate(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: Int(SessionChartViewModel.Constants.Time.daysInWeek / 2), to: date) ?? date
    }
    
    var dynamicTimeOffset: TimeInterval {
        return Double(SessionChartViewModel.Constants.TimeOffsets.halfYearDays) * SessionChartViewModel.Constants.Time.secondsInHour * SessionChartViewModel.Constants.Time.hoursInDay
    }
    
    var dynamicBarWidth: Double {
        return SessionChartViewModel.Constants.minBarWidth
    }
}

// MARK: - 1 Year
class YearXAxisStrategy: ChartXAxisStrategy {
    private let calendar = Calendar.current
    
    var xAxisValues: [Date] {
        let today = calendar.startOfDay(for: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var monthStarts: [Date] = []
        for i in 0..<SessionChartViewModel.Constants.Time.monthsInYear {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                monthStarts.append(monthStart)
            }
        }
        return monthStarts.sorted()
    }
    
    var xAxisDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        guard let start = xAxisValues.first,
              let end = xAxisValues.last else {
            return now...calendar.date(byAdding: .year, value: 1, to: now)!
        }
        
        let endWithPadding = calendar.date(byAdding: .month, value: 1, to: end)!
        return start...endWithPadding
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        return .dateTime.month(.narrow)
    }
    
    func centerDate(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.yearCenterDays, to: date) ?? date
    }
    
    var dynamicTimeOffset: TimeInterval {
        let hourOffset = SessionChartViewModel.Constants.Time.secondsInHour
        return hourOffset * SessionChartViewModel.Constants.Time.hoursInDay * SessionChartViewModel.Constants.DateOffsets.yearTimeOffsetDays
    }
    
    var dynamicBarWidth: Double {
        return SessionChartViewModel.Constants.defaultBarWidth / SessionChartViewModel.Constants.BarWidth.yearWidthMultiplier
    }
}
