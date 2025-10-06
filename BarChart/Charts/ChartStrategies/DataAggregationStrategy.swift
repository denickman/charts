//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

// MARK: - Base Protocols
protocol DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData]
}

// MARK: - Base Aggregation Strategy
class BaseAggregationStrategy {
    let calendar = Calendar.current
    
    func createAggregatedData(for sessions: [SessionData], date: Date) -> [AggregatedData] {
        [
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
    
    func createMaxAggregatedData(for sessions: [SessionData], date: Date) -> [AggregatedData] {
        let maxSittingSession = sessions.max(by: {
            ($0.sittingBase + $0.sittingOvertime) < ($1.sittingBase + $1.sittingOvertime)
        })
        
        let maxExercisingSession = sessions.max(by: {
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
    }
    
    func aggregateByDay(sessions: [SessionData], includeAllDays: Bool = false, dateRange: ClosedRange<Date>? = nil) -> [AggregatedData] {
        let groupedSessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.sittingDate)
        }
        
        let dates: [Date]
        if includeAllDays, let range = dateRange {
            dates = generateDateRange(from: range.lowerBound, to: range.upperBound)
        } else {
            dates = Array(groupedSessions.keys).sorted()
        }
        
        return dates.flatMap { date in
            let dailySessions = groupedSessions[date] ?? []
            return createMaxAggregatedData(for: dailySessions, date: date)
        }
    }
    
    private func generateDateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}

// MARK: - Day Aggregation
class DayDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let filteredSessions = sessions.filter { calendar.isDate($0.sittingDate, inSameDayAs: today) }
        return createMaxAggregatedData(for: filteredSessions, date: today)
    }
}

// MARK: - Three Days Aggregation
class ThreeDaysDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(
            byAdding: .day,
            value: SessionChartViewModel.Constants.DateOffsets.threeDays,
            to: today
        )!
        
        let dateRange = threeDaysAgo...today
        return aggregateByDay(sessions: sessions, includeAllDays: true, dateRange: dateRange)
    }
}

// MARK: - Week Aggregation
class WeekDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(
            byAdding: .day,
            value: SessionChartViewModel.Constants.DateOffsets.week,
            to: today
        )!
        
        let dateRange = weekStart...today
        return aggregateByDay(sessions: sessions, includeAllDays: true, dateRange: dateRange)
    }
}

// MARK: - 15 Days Aggregation
class HalfMonthDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: SessionChartViewModel.Constants.DateOffsets.halfOfMonth, to: today)!
        
        let dateRange = fifteenDaysAgo...today
        return aggregateByDay(sessions: sessions, includeAllDays: true, dateRange: dateRange)
    }
}

// MARK: - Month Aggregation
class MonthDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let thirtyDaysAgo = calendar.date(
            byAdding: .day,
            value: SessionChartViewModel.Constants.DateOffsets.month,
            to: calendar.startOfDay(for: Date())
        )!
        
        let dateRange = thirtyDaysAgo...Date()
        return aggregateByDay(sessions: sessions, includeAllDays: true, dateRange: dateRange)
    }
}

// MARK: - Period-based Aggregation
class PeriodBasedAggregationStrategy: BaseAggregationStrategy {
    let periodComponent: Calendar.Component
    let periodValue: Int
    
    init(periodComponent: Calendar.Component, periodValue: Int) {
        self.periodComponent = periodComponent
        self.periodValue = periodValue
    }
    
    func aggregateByPeriod(sessions: [SessionData]) -> [AggregatedData] {
        let groupedSessions = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, periodComponent], from: session.sittingDate)
            return calendar.date(from: components)!
        }
        
        return groupedSessions.flatMap { (periodStart, periodSessions) in
            createAggregatedData(for: periodSessions, date: periodStart)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Half Year Aggregation
class HalfYearDataAggregationStrategy: PeriodBasedAggregationStrategy, DataAggregationStrategy {
    init() {
        super.init(periodComponent: .weekOfYear, periodValue: SessionChartViewModel.Constants.DateOffsets.halfYearMonth)
    }
    
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        return aggregateByPeriod(sessions: sessions)
    }
}

// MARK: - Year Aggregation
class YearDataAggregationStrategy: PeriodBasedAggregationStrategy, DataAggregationStrategy {
    init() {
        super.init(periodComponent: .month, periodValue: SessionChartViewModel.Constants.Time.monthsInYear)
    }
    
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        return aggregateByPeriod(sessions: sessions)
    }
}
