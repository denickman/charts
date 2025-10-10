//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

protocol DataAggregator {
    func aggregate(_ sessions: [Session]) -> [ChartData]
}


class DayDataAggregator: DataAggregator {
    private let calendar = Calendar.current
    
    func aggregate(_ sessions: [Session]) -> [ChartData] {
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: today) }
        
        return aggregateByTimeIntervals(sessions: todaySessions, intervalHours: 2)
    }
    
    private func aggregateByTimeIntervals(sessions: [Session], intervalHours: Int) -> [ChartData] {
        var result: [ChartData] = []
        
        let grouped = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: session.date)
            let hour = components.hour ?? 0
            let intervalStart = hour - (hour % intervalHours)
            return calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: intervalStart
            ))!
        }
        
        for (intervalStart, intervalSessions) in grouped {
            let sittingTotal = intervalSessions.reduce(Activity(base: 0, extra: 0)) { result, session in
                Activity(
                    base: result.base + session.sitting.base,
                    extra: result.extra + session.sitting.extra
                )
            }
            
            let exercisingTotal = intervalSessions.reduce(Activity(base: 0, extra: 0)) { result, session in
                Activity(
                    base: result.base + session.exercising.base,
                    extra: result.extra + session.exercising.extra
                )
            }
            
            let startHour = calendar.component(.hour, from: intervalStart)
            let timeLabel = "\(startHour)-\(startHour + intervalHours)"
            let centerDate = calendar.date(byAdding: .hour, value: 1, to: intervalStart)!
            
            result.append(ChartData(
                date: centerDate,
                activityType: .sitting,
                base: sittingTotal.base,
                extra: sittingTotal.extra,
                timeLabel: timeLabel
            ))
            
            result.append(ChartData(
                date: centerDate,
                activityType: .exercising,
                base: exercisingTotal.base,
                extra: exercisingTotal.extra,
                timeLabel: timeLabel
            ))
        }
        
        return result.sorted { $0.date < $1.date }
    }
}

class ThreeDaysDataAggregator: DataAggregator {
    private let calendar = Calendar.current
    
    func aggregate(_ sessions: [Session]) -> [ChartData] {
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let dateRange = threeDaysAgo...today
        return aggregateByDay(sessions: sessions, includeEmptyDays: true, dateRange: dateRange)
    }
    
    private func aggregateByDay(sessions: [Session], includeEmptyDays: Bool, dateRange: ClosedRange<Date>) -> [ChartData] {
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        
        let dates = includeEmptyDays ? generateDateRange(from: dateRange.lowerBound, to: dateRange.upperBound) : Array(grouped.keys).sorted()
        
        return dates.flatMap { date in
            let daySessions = grouped[date] ?? []
            return createDailyData(for: daySessions, date: date)
        }
    }
    
    private func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
    
    private func createDailyData(for sessions: [Session], date: Date) -> [ChartData] {
        let maxSitting = sessions.max(by: { $0.sitting.total < $1.sitting.total })
        let maxExercising = sessions.max(by: { $0.exercising.total < $1.exercising.total })
        
        return [
            ChartData(
                date: date,
                activityType: .sitting,
                base: maxSitting?.sitting.base ?? 0,
                extra: maxSitting?.sitting.extra ?? 0,
                timeLabel: nil
            ),
            ChartData(
                date: date,
                activityType: .exercising,
                base: maxExercising?.exercising.base ?? 0,
                extra: maxExercising?.exercising.extra ?? 0,
                timeLabel: nil
            )
        ]
    }
}
