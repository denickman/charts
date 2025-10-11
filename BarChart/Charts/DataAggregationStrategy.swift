//
//  DataAggregationStrategy.swift
//  BarChart
//
//  Created by Denis Yaremenko on 11.10.2025.
//

import Foundation

protocol DataAggregationStrategy {
    func aggregate(sessions: [M_Session], calendar: Calendar) -> [AggregatedData]
}

struct IntraDayAggregationStrategy: DataAggregationStrategy {
    func aggregate(sessions: [M_Session], calendar: Calendar) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date()) // Get start of today (00:00)
        
        // Step 1: Group sessions by 2-hour intervals
        var groupedSessionsByTimeInterval: [Int: [M_Session]] = [:]
        
        for session in sessions {
            // Example: session.createdAt = 13:45
            let hour = calendar.component(.hour, from: session.createdAt) // hour = 13
            let intervalIndex = hour / ChartConfig.segmentHours // 13 / 2 = 6 (integer division)
            let intervalStartHour = intervalIndex * ChartConfig.segmentHours // 6 * 2 = 12
            
            // Create array for this interval if it doesn't exist
            if groupedSessionsByTimeInterval[intervalStartHour] == nil {
                groupedSessionsByTimeInterval[intervalStartHour] = []
            }
            // Add session to interval 12:00-14:00
            groupedSessionsByTimeInterval[intervalStartHour]!.append(session)
        }
        
        var aggregatedResults: [AggregatedData] = []
        
        // Step 2: Process each group of sessions
        for (intervalStartHour, groupedSessions) in groupedSessionsByTimeInterval.sorted(by: { $0.key < $1.key }) {
            // intervalStartHour = 12 (interval start)
            // Calculate interval center: start + 1 hour
            let intervalCenter = calendar.date(byAdding: .hour, value: intervalStartHour + 1, to: today)! // 00:00 + 13 hours = 13:00
            
            // Create aggregated data for this group
            let dataForThisInterval = groupedSessions.createAggregatedDataEntries(center: intervalCenter)
            aggregatedResults.append(contentsOf: dataForThisInterval)
        }
        
        return aggregatedResults
    }
}

struct DailyAggregationStrategy: DataAggregationStrategy {
    func aggregate(sessions: [M_Session], calendar: Calendar) -> [AggregatedData] {
        // Step 1: Group sessions by days manually
        var groupedSessionsByDay: [Date: [M_Session]] = [:]
        
        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.createdAt)
            
            if groupedSessionsByDay[dayStart] == nil {
                groupedSessionsByDay[dayStart] = []
            }
            groupedSessionsByDay[dayStart]!.append(session)
        }
        
        var aggregatedResults: [AggregatedData] = []
        
        // Step 2: Process each day group of sessions
        for (dayStart, groupedSessions) in groupedSessionsByDay.sorted(by: { $0.key < $1.key }) {
            
            let dayCenter = calendar.date(byAdding: .hour, value: ChartConfig.dayCenterHour, to: dayStart)!
            let dataForThisDay = groupedSessions.createAggregatedDataEntries(center: dayCenter)
            aggregatedResults.append(contentsOf: dataForThisDay)
        }
        
        return aggregatedResults
    }
 
}

extension Array where Element == M_Session {
    func createAggregatedDataEntries(center: Date) -> [AggregatedData] {
        let sittingBase = Double(self.reduce(0) { $0 + $1.sittingOverall })
        let sittingExtra = Double(self.reduce(0) { $0 + $1.sittingOvertime })
        let exercisingBase = Double(self.reduce(0) { $0 + $1.exercisingOverall })
        let exercisingExtra = Double(self.reduce(0) { $0 + $1.exercisingOvertime })
        
        var entries: [AggregatedData] = []
        
        if sittingBase + sittingExtra > 0 {
            entries.append(AggregatedData(
                periodCenterDate: center,
                activityType: .sitting,
                baseMinutes: sittingBase,
                extraMinutes: sittingExtra
            ))
        }
        if exercisingBase + exercisingExtra > 0 {
            entries.append(AggregatedData(
                periodCenterDate: center,
                activityType: .exercising,
                baseMinutes: exercisingBase,
                extraMinutes: exercisingExtra
            ))
        }
        return entries
    }
}
