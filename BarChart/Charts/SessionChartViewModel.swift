//
//  SessionChartViewModel.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation
import SwiftUI

@Observable
class SessionChartViewModel {
    
    enum Constants {
        static let defaultBarWidth: CGFloat = 14.0
        static let minBarWidth: CGFloat = 4.0
        static let maxBarWidth: CGFloat = 16.0
        static let defaultPeriodInMinutes: Double = 60.0
    }
    
    enum ChartPeriod: String, CaseIterable {
        case day = "1"
        case threeDays = "3"
        case week = "7"
        case month = "30"
        case halfYear = "180"
        case year = "365"
    }
    
    var selectedPeriod: ChartPeriod = .day
    let sessionsData: [SessionData] = testSessionsData
    
    var xAxisValues: [Date] {
        switch selectedPeriod {
        case .day:
            return fixedXAxisRange
        case .threeDays:
            return threeDaysXAxisRange
        case .week:
            return weekDateXAxisRange
        case .month:
            return monthXAxisRange
        case .halfYear:
            return halfYearXAxisRange
        case .year:
            return yearAxisRange
        }
    }
    
    
    var yAxisStep: Double {
        let maxValue = maxYValue * 1.1
        let oneHour: Double = 60.0
        
        if maxValue <= oneHour {
            return 10 //0, 15, 30, 45, 60
        } else if maxValue <= oneHour * 2 {
            return 15 // 0, 30, 60, 90, 120
        } else if maxValue <= oneHour * 4 {
            return 30 // 0, 60, 120, 180, 240
        } else {
            let roughStep = maxValue / 4
            let roundedStep = (roughStep / oneHour).rounded() * oneHour
            return max(roundedStep, oneHour)
        }
    }
    
    var maxYValue: Double {
        switch selectedPeriod {
        case .day, .threeDays:
            let maxSitting = dailySessionsData.map { $0.sittingBase + $0.sittingOvertime }.max() ?? 0
            let maxExercising = dailySessionsData.map { $0.exercisingBase + $0.exercisingExtra }.max() ?? 0
            return max(maxSitting, maxExercising, Constants.defaultPeriodInMinutes)
        case .week:
            let maxValue = weeklySessionsData.map { $0.base + $0.extra }.max() ?? 0
            return max(maxValue, Constants.defaultPeriodInMinutes)
        case .month:
            let maxValue = monthlySessionsData.map { $0.base + $0.extra }.max() ?? 0
            return max(maxValue, Constants.defaultPeriodInMinutes)
        case .halfYear:
            let maxValue = halfYearSessionsData.map { $0.base + $0.extra }.max() ?? 0
            return max(maxValue, Constants.defaultPeriodInMinutes)
        case .year:
            let maxValue = yearlySessionsData.map { $0.base + $0.extra }.max() ?? 0
            return max(maxValue, Constants.defaultPeriodInMinutes)
        }
    }
    
    // Labels for the X-axis
    
    private var fixedXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        return [0, 6, 12, 18].compactMap { calendar.date(bySettingHour: $0, minute: 0, second: 0, of: calendar.date(from: components)!) }
    }
    
    private var threeDaysXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-2...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private var weekDateXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private var monthXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today)!
        
        // Create tags for each week (approximately every 7 days)
        var weekStarts: [Date] = []
        for i in 0..<5 { // 5 weeks max
            let daysOffset = i * 7
            let weekStart = calendar.date(byAdding: .day, value: daysOffset, to: thirtyDaysAgo)!
            if weekStart <= today {
                weekStarts.append(weekStart)
            }
        }
        
        return weekStarts
    }
    
    private var halfYearXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Start of current month - используем тот же подход что и в year
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        // Create 6 months, starting from the current one and going backwards
        var monthStarts: [Date] = []
        
        for i in 0..<6 {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                monthStarts.append(monthStart)
            }
        }
        
        return monthStarts.sorted()
    }
    
    // Labels for the Y-axis
    
    private var yearAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Start of current month
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        // Create 12 months, starting from the current one and going backwards
        var monthStarts: [Date] = []
        
        for i in 0..<12 {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                monthStarts.append(monthStart)
            }
        }
        
        return monthStarts.sorted()
    }
}

extension SessionChartViewModel {
    
    
    var xAxisLabelFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .day:
            return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
        case .month:
            return .dateTime.day()
        case .halfYear:
            return .dateTime.month(.abbreviated)
        case .year:
            return .dateTime.month(.narrow)
        default:
            return .dateTime.weekday(.abbreviated)
        }
    }
    
    func barColor(for activityType: AggregatedData.ActivityType) -> Color {
        switch activityType {
        case .sitting: return .red
        case .exercising: return .green
        }
    }
    
    func calculateBarPosition(for data: AggregatedData) -> Date {
        let centerDate = centerDate(for: data.date)
        let timeOffset: TimeInterval = data.activityType == .sitting ?
            -dynamicTimeOffset : dynamicTimeOffset
        return centerDate.addingTimeInterval(timeOffset)
    }
    
    func centerDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let halfOfDay = 12
        let halfOfMonth = 15
        let halfOfWeek = 3.5
        
        switch selectedPeriod {
            
        case .week:
            return calendar.date(bySettingHour: halfOfDay, minute: 0, second: 0, of: date) ?? date
            

        case .year:
            return calendar.date(byAdding: .day, value: halfOfMonth, to: date) ?? date
            
        default:
            // day / 3 days/ 1 month/ 6 months
            return date
        }
    }
    
    var dynamicTimeOffset: TimeInterval {
        let hourOffset: TimeInterval = 3600
        let quarterOfMonth: Double = 7.5
        let hoursPerDay: Double = 24
        
        //        let halfDayOffset: TimeInterval = 12 * 3600 // 12 часов
        
        switch selectedPeriod {
        case .week:
            return hourOffset * 4
            
        case .month:
            return hourOffset * 6
            //        case .halfYear:
            //               return halfDayOffset
            
        case .halfYear:
            // Смещение на полнедели (3.5 дня) для визуального разделения
            return 3.5 * 24 * 3600 // 3.5 дня в секундах
            
        case .year:
            return hourOffset * hoursPerDay * quarterOfMonth
        default: // day / 3 days / 1 month
            return 0
        }
    }
    
    var dynamicBarWidth: Double {
        switch selectedPeriod {
        case .day, .threeDays:
            let sessionCount = dailySessionsData.count * 2 // 2 phases in each session
            return calculateBarWidth(for: sessionCount)
        case .week:
            return Constants.defaultBarWidth
        case .month, .halfYear:
            return Constants.minBarWidth
        case .year:
            return Constants.defaultBarWidth / 1.2
        }
    }
    
    private func calculateBarWidth(for dataCount: Int) -> Double {
        let minWidth = Constants.minBarWidth
        let maxWidth = Constants.maxBarWidth
        let baseWidth = Constants.defaultBarWidth
        
        let lowDataRange = 0...5      // Little data - maximum width
        let mediumDataRange = 6...10  // Medium amount - reduce width
        let highDataRange = 11...     // Lots of data - minimum width
        
        switch dataCount {
        case lowDataRange:
            return maxWidth
            
        case mediumDataRange:
            // Linearly decrease the width from baseWidth to minWidth
            let positionInRange = Double(dataCount - mediumDataRange.lowerBound)
            let totalRangeLength = Double(mediumDataRange.count)
            let widthRange = baseWidth - minWidth
            
            let calculatedWidth = baseWidth - (positionInRange / totalRangeLength) * widthRange
            return max(minWidth, calculatedWidth)
            
        case highDataRange:
            return minWidth
            
        default:
            return baseWidth
        }
    }
}

extension SessionChartViewModel {
    
    var dailySessionsData: [SessionData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if selectedPeriod == .day {
            return sessionsData.filter { calendar.isDate($0.sittingDate, inSameDayAs: today) }
        } else if selectedPeriod == .threeDays {
            let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
            return sessionsData.filter { session in
                let sessionDate = calendar.startOfDay(for: session.sittingDate)
                return sessionDate >= threeDaysAgo && sessionDate <= today
            }
        } else {
            return []
        }
    }
    
    var weeklySessionsData: [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        
        var allDays: [Date] = []
        var currentDate = weekStart
        while currentDate <= today {
            allDays.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let groupedSessions = Dictionary(grouping: sessionsData) { session in
            calendar.startOfDay(for: session.sittingDate)
        }
        
        return allDays.flatMap { date in
            let sessions = groupedSessions[date] ?? []
            let sittingBaseTotal = sessions.reduce(0) { $0 + $1.sittingBase }
            let sittingOvertimeTotal = sessions.reduce(0) { $0 + $1.sittingOvertime }
            let exercisingBaseTotal = sessions.reduce(0) { $0 + $1.exercisingBase }
            let exercisingExtraTotal = sessions.reduce(0) { $0 + $1.exercisingExtra }
            
            return [
                AggregatedData(
                    date: date,
                    activityType: .sitting,
                    base: sittingBaseTotal,
                    extra: sittingOvertimeTotal
                ),
                AggregatedData(
                    date: date,
                    activityType: .exercising,
                    base: exercisingBaseTotal,
                    extra: exercisingExtraTotal
                )
            ]
        }
    }
    
    var monthlySessionsData: [AggregatedData] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: Date()))!
        
        let groupedSessions = Dictionary(grouping: sessionsData) { session in
            calendar.startOfDay(for: session.sittingDate)
        }
        
        // Create an array of all days in the last 30 days
        var allDays: [Date] = []
        var currentDate = thirtyDaysAgo
        while currentDate <= Date() {
            allDays.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // For each day we create AggregatedData
        return allDays.flatMap { date in
            let sessions = groupedSessions[date] ?? []
            let sittingBaseTotal = sessions.reduce(0) { $0 + $1.sittingBase }
            let sittingOvertimeTotal = sessions.reduce(0) { $0 + $1.sittingOvertime }
            let exercisingBaseTotal = sessions.reduce(0) { $0 + $1.exercisingBase }
            let exercisingExtraTotal = sessions.reduce(0) { $0 + $1.exercisingExtra }
            
            return [
                AggregatedData(
                    date: date,
                    activityType: .sitting,
                    base: sittingBaseTotal,
                    extra: sittingOvertimeTotal
                ),
                AggregatedData(
                    date: date,
                    activityType: .exercising,
                    base: exercisingBaseTotal,
                    extra: exercisingExtraTotal
                )
            ]
        }
    }
    
    var yearlySessionsData: [AggregatedData] {
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var displayMonths: [Date] = []
        for i in 0..<12 {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                displayMonths.append(monthStart)
            }
        }
        
        let groupedSessions = Dictionary(grouping: sessionsData) { session in
            let components = calendar.dateComponents([.year, .month], from: session.sittingDate)
            return calendar.date(from: components)!
        }
        
        return displayMonths.flatMap { monthStart in
            let sessions = groupedSessions[monthStart] ?? []
            let sittingBaseTotal = sessions.reduce(0) { $0 + $1.sittingBase }
            let sittingOvertimeTotal = sessions.reduce(0) { $0 + $1.sittingOvertime }
            let exercisingBaseTotal = sessions.reduce(0) { $0 + $1.exercisingBase }
            let exercisingExtraTotal = sessions.reduce(0) { $0 + $1.exercisingExtra }
            
            return [
                AggregatedData(
                    date: monthStart,
                    activityType: .sitting,
                    base: sittingBaseTotal,
                    extra: sittingOvertimeTotal
                ),
                AggregatedData(
                    date: monthStart,
                    activityType: .exercising,
                    base: exercisingBaseTotal,
                    extra: exercisingExtraTotal
                )
            ]
        }.sorted { $0.date < $1.date }
    }
    
    var halfYearSessionsData: [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Start of current month
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        // 6 months ago from start of current month
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -5, to: startOfCurrentMonth)!
        
        // Grouping sessions by week
        let groupedByWeek = Dictionary(grouping: sessionsData) { session in
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.sittingDate))!
            return weekStart
        }
        
        // Create an array of all weeks for the last 6 months
        var allWeeks: [Date] = []
        var currentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sixMonthsAgo))!
        
        while currentWeek <= today {
            allWeeks.append(currentWeek)
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek)!
        }
        
        // For each week we create AggregatedData
        return allWeeks.flatMap { weekStart in
            let sessions = groupedByWeek[weekStart] ?? []
            let sittingBaseTotal = sessions.reduce(0) { $0 + $1.sittingBase }
            let sittingOvertimeTotal = sessions.reduce(0) { $0 + $1.sittingOvertime }
            let exercisingBaseTotal = sessions.reduce(0) { $0 + $1.exercisingBase }
            let exercisingExtraTotal = sessions.reduce(0) { $0 + $1.exercisingExtra }
            
            return [
                AggregatedData(
                    date: weekStart,
                    activityType: .sitting,
                    base: sittingBaseTotal,
                    extra: sittingOvertimeTotal
                ),
                AggregatedData(
                    date: weekStart,
                    activityType: .exercising,
                    base: exercisingBaseTotal,
                    extra: exercisingExtraTotal
                )
            ]
        }
    }
}




// Temporary extension need to delete

extension SessionChartViewModel {
    
    var totalSitting: Double {
        let data: [AggregatedData]
        switch selectedPeriod {
        case .day, .threeDays:
            return dailySessionsData.reduce(0) { $0 + $1.sittingBase + $1.sittingOvertime }
        case .week: data = weeklySessionsData
        case .month: data = monthlySessionsData
        case .year: data = yearlySessionsData
        case .halfYear: data = halfYearSessionsData
        }
        
        return data
            .filter { $0.activityType == .sitting }
            .reduce(0) { $0 + $1.base + $1.extra }
    }
    
    var totalExercising: Double {
        let data: [AggregatedData]
        switch selectedPeriod {
        case .day, .threeDays:
            return dailySessionsData.reduce(0) { $0 + $1.exercisingBase + $1.exercisingExtra }
        case .week: data = weeklySessionsData
        case .month: data = monthlySessionsData
        case .year: data = yearlySessionsData
        case .halfYear: data = halfYearSessionsData
        }
        
        return data
            .filter { $0.activityType == .exercising }
            .reduce(0) { $0 + $1.base + $1.extra }
    }
}
