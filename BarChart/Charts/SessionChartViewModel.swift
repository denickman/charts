//
//  SessionChartViewModel.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import SwiftUI

@Observable
class SessionChartViewModel {
    
    enum Constants {
        static let defaultBarWidth: CGFloat = 14.0
        static let minBarWidth: CGFloat = 4.0
        static let maxBarWidth: CGFloat = 16.0
        static let defaultPeriodInMinutes: Double = 60.0
        
        enum Time {
            static let secondsInHour: TimeInterval = 3600
            static let minutesInHour: Double = 60.0
            static let hoursInDay: Double = 24.0
            static let daysInWeek: Double = 7.0
            static let daysInMonth: Int = 30
            static let monthsInHalfYear: Int = 6
            static let monthsInYear: Int = 12
        }
        
        enum BarWidth {
            static let lowDataThreshold: Int = 8
            static let mediumDataThreshold: Int = 16
            static let yearWidthMultiplier: Double = 1.2
        }
        
        enum YAxis {
            static let stepSmall: Double = 10
            static let stepMedium: Double = 15
            static let stepLarge: Double = 30
            static let maxMultiplier: Double = 1.1
        }
        
        enum DateOffsets {
            static let threeDays: Int = -2
            static let week: Int = -6
            static let month: Int = -29
            static let halfYearMonth: Int = -5
            static let yearMonthStart: Int = -11
            
            static let dayCenterHour: Int = 12
            static let yearCenterDays: Int = 15
            static let yearTimeOffsetDays: Double = 7.5
        }
        
        enum TimeOffsets {
            static let weekHours: Double = 4
            static let monthHours: Double = 6
            static let halfYearDays: Int = 1
        }
        
        enum DataRanges {
            static let dayHours: [Int] = [0, 6, 12, 18]
            static let threeDaysRange: ClosedRange<Int> = -2...0
            static let weekRange: ClosedRange<Int> = -6...0
            static let monthWeeks: Int = 5
            static let weekDaysInterval: Int = 7
        }
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
        let maxValue = maxYValue * Constants.YAxis.maxMultiplier
        let oneHour = Constants.Time.minutesInHour
        
        if maxValue <= oneHour {
            return Constants.YAxis.stepSmall
        } else if maxValue <= oneHour * 2 {
            return Constants.YAxis.stepMedium
        } else if maxValue <= oneHour * 4 {
            return Constants.YAxis.stepLarge
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
        return Constants.DataRanges.dayHours.compactMap {
            calendar.date(bySettingHour: $0, minute: 0, second: 0, of: calendar.date(from: components)!)
        }
    }
    
    private var threeDaysXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return Constants.DataRanges.threeDaysRange.compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    private var weekDateXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return Constants.DataRanges.weekRange.compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    private var monthXAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: Constants.DateOffsets.month, to: today)!
        
        var weekStarts: [Date] = []
        for i in 0..<Constants.DataRanges.monthWeeks {
            let daysOffset = i * Constants.DataRanges.weekDaysInterval
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
        
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var monthStarts: [Date] = []
        
        for i in 0..<Constants.Time.monthsInHalfYear {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                monthStarts.append(monthStart)
            }
        }
        
        return monthStarts.sorted()
    }
    
    private var yearAxisRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var monthStarts: [Date] = []
        
        for i in 0..<Constants.Time.monthsInYear {
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
        
        switch selectedPeriod {
        case .week:
            return calendar.date(bySettingHour: Constants.DateOffsets.dayCenterHour, minute: 0, second: 0, of: date) ?? date
        case .year:
            return calendar.date(byAdding: .day, value: Constants.DateOffsets.yearCenterDays, to: date) ?? date
        case .halfYear:
            return calendar.date(byAdding: .day, value: Int(Constants.Time.daysInWeek / 2), to: date) ?? date
        default:
            return date
        }
    }
    
    var dynamicTimeOffset: TimeInterval {
        let hourOffset = Constants.Time.secondsInHour
        
        switch selectedPeriod {
        case .week:
            return hourOffset * Constants.TimeOffsets.weekHours
        case .month:
            return hourOffset * Constants.TimeOffsets.monthHours
        case .halfYear:
            return Double(Constants.TimeOffsets.halfYearDays) * Constants.Time.secondsInHour * Constants.Time.hoursInDay
        case .year:
            return hourOffset * Constants.Time.hoursInDay * Constants.DateOffsets.yearTimeOffsetDays
        default:
            return 0
        }
    }
    
    var dynamicBarWidth: Double {
        switch selectedPeriod {
        case .day:
            let sessionCount = dailySessionsData.count * 2 // 2 phases in each session
            return calculateBarWidth(for: sessionCount)
        case .week:
            return Constants.defaultBarWidth
        case .month, .halfYear, .threeDays:
            return Constants.minBarWidth
        case .year:
            return Constants.defaultBarWidth / Constants.BarWidth.yearWidthMultiplier
        }
    }
    
    private func calculateBarWidth(for dataCount: Int) -> Double {
        let minWidth = Constants.minBarWidth
        let maxWidth = Constants.maxBarWidth
        let baseWidth = Constants.defaultBarWidth
        
        let lowDataRange = 0...Constants.BarWidth.lowDataThreshold
        let mediumDataRange = (Constants.BarWidth.lowDataThreshold + 1)...Constants.BarWidth.mediumDataThreshold
        let highDataRange = (Constants.BarWidth.mediumDataThreshold + 1)...Int.max
        
        switch dataCount {
        case lowDataRange:
            return maxWidth
            
        case mediumDataRange:
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
            let threeDaysAgo = calendar.date(byAdding: .day, value: Constants.DateOffsets.threeDays, to: today)!
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
        let weekStart = calendar.date(byAdding: .day, value: Constants.DateOffsets.week, to: today)!
        
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
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: Constants.DateOffsets.month, to: calendar.startOfDay(for: Date()))!
        
        let groupedSessions = Dictionary(grouping: sessionsData) { session in
            calendar.startOfDay(for: session.sittingDate)
        }
        
        var allDays: [Date] = []
        var currentDate = thirtyDaysAgo
        while currentDate <= Date() {
            allDays.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
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
    
    var yearlySessionsData: [AggregatedData] {
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var displayMonths: [Date] = []
        for i in 0..<Constants.Time.monthsInYear {
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
        
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        let sixMonthsAgo = calendar.date(byAdding: .month, value: Constants.DateOffsets.halfYearMonth, to: startOfCurrentMonth)!
        
        let sixMonthsAgoWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sixMonthsAgo))!
        
        var allWeeks: [Date] = []
        var currentWeek = sixMonthsAgoWeekStart
        
        while currentWeek <= today {
            allWeeks.append(currentWeek)
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek)!
        }
        
        let groupedByWeek = Dictionary(grouping: sessionsData) { session in
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.sittingDate))!
            return weekStart
        }
        
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

extension SessionChartViewModel {
    
    var xAxisDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return startOfDay...endOfDay
            
        case .threeDays:
            let start = calendar.date(byAdding: .day, value: Constants.DateOffsets.threeDays, to: calendar.startOfDay(for: now))!
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            return start...end
            
        case .week:
            let start = calendar.date(byAdding: .day, value: Constants.DateOffsets.week, to: calendar.startOfDay(for: now))!
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            return start...end
            
        case .month:
            let start = calendar.date(byAdding: .day, value: Constants.DateOffsets.month, to: calendar.startOfDay(for: now))!
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            return start...end
            
        case .halfYear:
               guard let start = halfYearXAxisRange.first,
                     let end = halfYearXAxisRange.last else {
                   return now...calendar.date(byAdding: .month, value: 1, to: now)!
               }
               let startWithPadding = calendar.date(byAdding: .day, value: -Constants.DataRanges.weekDaysInterval, to: start)!
               let endWithPadding = calendar.date(byAdding: .month, value: 1, to: end)!
               return startWithPadding...endWithPadding
            
        case .year:
            guard let start = yearAxisRange.first,
                  let end = yearAxisRange.last else {
                return now...calendar.date(byAdding: .year, value: 1, to: now)!
            }
            let endWithPadding = calendar.date(byAdding: .month, value: 1, to: end)!
            return start...endWithPadding
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

