//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

import Foundation

// MARK: - Base Protocols
protocol DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData]
}

// MARK: - Base Aggregation Strategy
class BaseAggregationStrategy {
    let calendar = Calendar.current
    
    func createAggregatedData(for sessions: [SessionData], date: Date, intervalLabel: String? = nil) -> [AggregatedData] {
        [
            AggregatedData(
                date: date,
                activityType: .sitting,
                base: sessions.reduce(0) { $0 + $1.sittingBase },
                extra: sessions.reduce(0) { $0 + $1.sittingOvertime },
                intervalLabel: intervalLabel
            ),
            AggregatedData(
                date: date,
                activityType: .exercising,
                base: sessions.reduce(0) { $0 + $1.exercisingBase },
                extra: sessions.reduce(0) { $0 + $1.exercisingExtra },
                intervalLabel: intervalLabel
            )
        ]
    }
    
    func createMaxAggregatedData(for sessions: [SessionData], date: Date, intervalLabel: String? = nil) -> [AggregatedData] {
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
                extra: maxSittingSession?.sittingOvertime ?? 0,
                intervalLabel: intervalLabel
            ),
            AggregatedData(
                date: date,
                activityType: .exercising,
                base: maxExercisingSession?.exercisingBase ?? 0,
                extra: maxExercisingSession?.exercisingExtra ?? 0,
                intervalLabel: intervalLabel
            )
        ]
    }
    
    // Updated method for 2-hour interval aggregation with proper labeling
    func aggregateByTwoHourIntervals(sessions: [SessionData]) -> [AggregatedData] {
        let calendar = Calendar.current
        var result: [AggregatedData] = []
        
        // Group sessions by 2-hour intervals
        let groupedByInterval = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: session.sittingDate)
            let hour = components.hour ?? 0
            let intervalStartHour = hour - (hour % 2) // Group into 2-hour blocks: 0-2, 2-4, etc.
            return calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: intervalStartHour
            ))!
        }
        
        // Create aggregated data for each interval
        for (intervalStart, intervalSessions) in groupedByInterval {
            let sittingTotalBase = intervalSessions.reduce(0) { $0 + $1.sittingBase }
            let sittingTotalExtra = intervalSessions.reduce(0) { $0 + $1.sittingOvertime }
            let exercisingTotalBase = intervalSessions.reduce(0) { $0 + $1.exercisingBase }
            let exercisingTotalExtra = intervalSessions.reduce(0) { $0 + $1.exercisingExtra }
            
            // Create interval label (e.g., "10-12")
            let startHour = calendar.component(.hour, from: intervalStart)
            let endHour = startHour + 2
            let intervalLabel = "\(startHour)-\(endHour)"
            
            // Center date in the middle of the 2-hour interval
            let centerDate = calendar.date(byAdding: .hour, value: 1, to: intervalStart)!
            
            result.append(AggregatedData(
                date: centerDate,
                activityType: .sitting,
                base: sittingTotalBase,
                extra: sittingTotalExtra,
                intervalLabel: intervalLabel
            ))
            
            result.append(AggregatedData(
                date: centerDate,
                activityType: .exercising,
                base: exercisingTotalBase,
                extra: exercisingTotalExtra,
                intervalLabel: intervalLabel
            ))
        }
        
        return result.sorted { $0.date < $1.date }
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

// MARK: - Day Aggregation (2-hour intervals)
class DayDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let filteredSessions = sessions.filter { calendar.isDate($0.sittingDate, inSameDayAs: today) }
        return aggregateByTwoHourIntervals(sessions: filteredSessions)
    }
}

//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

// MARK: - Three Days Aggregation
class ThreeDaysDataAggregationStrategy: BaseAggregationStrategy, DataAggregationStrategy {
    func getAggregateData(from sessions: [SessionData]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(
            byAdding: .day,
            value: ChartConfig.DateOffsets.threeDays,
            to: today
        )!
        
        let dateRange = threeDaysAgo...today
        return aggregateByDay(sessions: sessions, includeAllDays: true, dateRange: dateRange)
    }
}
