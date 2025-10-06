//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

protocol DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData]
}

// MARK: - Day

class DayDataAggregationStrategy: DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let filteredSessions = sessions.filter { calendar.isDate($0.sittingDate, inSameDayAs: today) }
        
        return createMaxAggregatedData(from: filteredSessions)
    }
    
    private func createMaxAggregatedData(from sessions: [SessionData]) -> [AggregatedData] {
        let maxSittingSession = sessions.max(by: {
            ($0.sittingBase + $0.sittingOvertime) < ($1.sittingBase + $1.sittingOvertime)
        })
        
        let maxExercisingSession = sessions.max(by: {
            ($0.exercisingBase + $0.exercisingExtra) < ($1.exercisingBase + $1.exercisingExtra)
        })
        
        return [
            AggregatedData(
                date: Date(),
                activityType: .sitting,
                base: maxSittingSession?.sittingBase ?? 0,
                extra: maxSittingSession?.sittingOvertime ?? 0
            ),
            AggregatedData(
                date: Date(),
                activityType: .exercising,
                base: maxExercisingSession?.exercisingBase ?? 0,
                extra: maxExercisingSession?.exercisingExtra ?? 0
            )
        ]
    }
}

// MARK: - Three Days
class ThreeDaysDataAggregationStrategy: DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.threeDays, to: today)!
        
        let filteredSessions = sessions.filter { session in
            let sessionDate = calendar.startOfDay(for: session.sittingDate)
            return sessionDate >= threeDaysAgo && sessionDate <= today
        }
        
        return createDailyMaxAggregatedData(from: filteredSessions)
    }
    
    private func createDailyMaxAggregatedData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let groupedSessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.sittingDate)
        }
        
        return groupedSessions.flatMap { (date, dailySessions) in
            let maxSittingSession = dailySessions.max(by: {
                ($0.sittingBase + $0.sittingOvertime) < ($1.sittingBase + $1.sittingOvertime)
            })
            
            let maxExercisingSession = dailySessions.max(by: {
                ($0.exercisingBase + $0.exercisingExtra) < ($1.exercisingBase + $1.exercisingExtra)
            })
            
            return [
                AggregatedData(
                    date: date,
                    activityType: .sitting,
                    base: maxSittingSession?.sittingBase ?? 0,
                    extra: maxSittingSession?.sittingOvertime ?? 0
                ),
                AggregatedData(
                    date: date,
                    activityType: .exercising,
                    base: maxExercisingSession?.exercisingBase ?? 0,
                    extra: maxExercisingSession?.exercisingExtra ?? 0
                )
            ]
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - One Week
class WeekDataAggregationStrategy: DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.week, to: today)!
        
        var allDays: [Date] = []
        var currentDate = weekStart
        while currentDate <= today {
            allDays.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let groupedSessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.sittingDate)
        }
        
        return allDays.flatMap { date in
            let sessions = groupedSessions[date] ?? []
            return [
                AggregatedData(
                    date: date,
                    activityType: .sitting,
                    base: sessions.reduce(0) { $0 + $1.sittingBase },
                    extra: sessions.reduce(0) { $0 + $1.sittingOvertime }
                ),
                AggregatedData(
                    date: date,
                    activityType: .exercising,
                    base: sessions.reduce(0) { $0 + $1.exercisingBase },
                    extra: sessions.reduce(0) { $0 + $1.exercisingExtra }
                )
            ]
        }
    }
}

// MARK: - One Month
class MonthDataAggregationStrategy: DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.month, to: calendar.startOfDay(for: Date()))!
        
        let groupedSessions = Dictionary(grouping: sessions) { session in
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
            return [
                AggregatedData(
                    date: date,
                    activityType: .sitting,
                    base: sessions.reduce(0) { $0 + $1.sittingBase },
                    extra: sessions.reduce(0) { $0 + $1.sittingOvertime }
                ),
                AggregatedData(
                    date: date,
                    activityType: .exercising,
                    base: sessions.reduce(0) { $0 + $1.exercisingBase },
                    extra: sessions.reduce(0) { $0 + $1.exercisingExtra }
                )
            ]
        }
    }
}

// MARK: - Half Year
class HalfYearDataAggregationStrategy: DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        let sixMonthsAgo = calendar.date(byAdding: .month, value: SessionChartViewModel.Constants.DateOffsets.halfYearMonth, to: startOfCurrentMonth)!
        
        let sixMonthsAgoWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sixMonthsAgo))!
        
        var allWeeks: [Date] = []
        var currentWeek = sixMonthsAgoWeekStart
        
        while currentWeek <= today {
            allWeeks.append(currentWeek)
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek)!
        }
        
        let groupedByWeek = Dictionary(grouping: sessions) { session in
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.sittingDate))!
            return weekStart
        }
        
        return allWeeks.flatMap { weekStart in
            let sessions = groupedByWeek[weekStart] ?? []
            return [
                AggregatedData(
                    date: weekStart,
                    activityType: .sitting,
                    base: sessions.reduce(0) { $0 + $1.sittingBase },
                    extra: sessions.reduce(0) { $0 + $1.sittingOvertime }
                ),
                AggregatedData(
                    date: weekStart,
                    activityType: .exercising,
                    base: sessions.reduce(0) { $0 + $1.exercisingBase },
                    extra: sessions.reduce(0) { $0 + $1.exercisingExtra }
                )
            ]
        }
    }
}

// MARK: - One Year
class YearDataAggregationStrategy: DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents) else { return [] }
        
        var displayMonths: [Date] = []
        for i in 0..<SessionChartViewModel.Constants.Time.monthsInYear {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                displayMonths.append(monthStart)
            }
        }
        
        let groupedSessions = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month], from: session.sittingDate)
            return calendar.date(from: components)!
        }
        
        return displayMonths.flatMap { monthStart in
            let sessions = groupedSessions[monthStart] ?? []
            return [
                AggregatedData(
                    date: monthStart,
                    activityType: .sitting,
                    base: sessions.reduce(0) { $0 + $1.sittingBase },
                    extra: sessions.reduce(0) { $0 + $1.sittingOvertime }
                ),
                AggregatedData(
                    date: monthStart,
                    activityType: .exercising,
                    base: sessions.reduce(0) { $0 + $1.exercisingBase },
                    extra: sessions.reduce(0) { $0 + $1.exercisingExtra }
                )
            ]
        }.sorted { $0.date < $1.date }
    }
}
