//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

protocol DataAggregator {
    func aggregate(_ sessions: [M_Session]) -> [ChartData]
}

class DayDataAggregator: DataAggregator {
    private let calendar = Calendar.current
    
    func aggregate(_ sessions: [M_Session]) -> [ChartData] {
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessions.filter {
            calendar.isDate($0.sittingStartedAt, inSameDayAs: today) ||
            calendar.isDate($0.exercisingStartedAt, inSameDayAs: today)
        }
        
        return aggregateByTimeIntervals(sessions: todaySessions, intervalHours: 2)
    }
    
    private func aggregateByTimeIntervals(sessions: [M_Session], intervalHours: Int) -> [ChartData] {
        var result: [ChartData] = []
        
        // Группируем сессии по интервалам для сидения
        let sittingGrouped = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: session.sittingStartedAt)
            let hour = components.hour ?? 0
            let intervalStart = hour - (hour % intervalHours)
            return calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: intervalStart
            ))!
        }
        
        // Группируем сессии по интервалам для упражнений
        let exercisingGrouped = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: session.exercisingStartedAt)
            let hour = components.hour ?? 0
            let intervalStart = hour - (hour % intervalHours)
            return calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: intervalStart
            ))!
        }
        
        // Обрабатываем сидения
        for (intervalStart, intervalSessions) in sittingGrouped {
            let sittingTotalBase = intervalSessions.reduce(0) { $0 + Double($1.sittingOverall) }
            let sittingTotalExtra = intervalSessions.reduce(0) { $0 + Double($1.sittingOvertime) }
            
            let timeLabel = createTimeLabel(for: intervalStart, intervalHours: intervalHours)
            let centerDate = calendar.date(byAdding: .hour, value: intervalHours/2, to: intervalStart)!
            
            result.append(ChartData(
                date: centerDate,
                activityType: .sitting,
                base: sittingTotalBase,
                extra: sittingTotalExtra,
                timeLabel: timeLabel
            ))
        }
        
        // Обрабатываем упражнения
        for (intervalStart, intervalSessions) in exercisingGrouped {
            let exercisingTotalBase = intervalSessions.reduce(0) { $0 + Double($1.exercisingOverall) }
            let exercisingTotalExtra = intervalSessions.reduce(0) { $0 + Double($1.exercisingOvertime) }
            
            let timeLabel = createTimeLabel(for: intervalStart, intervalHours: intervalHours)
            let centerDate = calendar.date(byAdding: .hour, value: intervalHours/2, to: intervalStart)!
            
            result.append(ChartData(
                date: centerDate,
                activityType: .exercising,
                base: exercisingTotalBase,
                extra: exercisingTotalExtra,
                timeLabel: timeLabel
            ))
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    private func createTimeLabel(for intervalStart: Date, intervalHours: Int) -> String {
        let startHour = calendar.component(.hour, from: intervalStart)
        let endHour = startHour + intervalHours
        return "\(startHour)-\(endHour)"
    }
}

class ThreeDaysDataAggregator: DataAggregator {
    private let calendar = Calendar.current
    
    func aggregate(_ sessions: [M_Session]) -> [ChartData] {
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let dateRange = threeDaysAgo...today
        return aggregateByDay(sessions: sessions, includeEmptyDays: true, dateRange: dateRange)
    }
    
    private func aggregateByDay(sessions: [M_Session], includeEmptyDays: Bool, dateRange: ClosedRange<Date>) -> [ChartData] {
        // Группируем по дням для сидения
        let sittingGrouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.sittingStartedAt)
        }
        
        // Группируем по дням для упражнений
        let exercisingGrouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.exercisingStartedAt)
        }
        
        let dates = includeEmptyDays ? generateDateRange(from: dateRange.lowerBound, to: dateRange.upperBound) :
            Array(Set(sittingGrouped.keys).union(Set(exercisingGrouped.keys))).sorted()
        
        return dates.flatMap { date in
            let daySittingSessions = sittingGrouped[date] ?? []
            let dayExercisingSessions = exercisingGrouped[date] ?? []
            
            return createDailyData(
                sittingSessions: daySittingSessions,
                exercisingSessions: dayExercisingSessions,
                date: date
            )
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
    
    private func createDailyData(sittingSessions: [M_Session], exercisingSessions: [M_Session], date: Date) -> [ChartData] {
        let maxSitting = sittingSessions.max(by: {
            ($0.sittingOverall + $0.sittingOvertime) < ($1.sittingOverall + $1.sittingOvertime)
        })
        
        let maxExercising = exercisingSessions.max(by: {
            ($0.exercisingOverall + $0.exercisingOvertime) < ($1.exercisingOverall + $1.exercisingOvertime)
        })
        
        return [
            ChartData(
                date: date,
                activityType: .sitting,
                base: Double(maxSitting?.sittingOverall ?? 0),
                extra: Double(maxSitting?.sittingOvertime ?? 0),
                timeLabel: nil
            ),
            ChartData(
                date: date,
                activityType: .exercising,
                base: Double(maxExercising?.exercisingOverall ?? 0),
                extra: Double(maxExercising?.exercisingOvertime ?? 0),
                timeLabel: nil
            )
        ]
    }
}
