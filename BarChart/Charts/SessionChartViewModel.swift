//
//  SessionChartViewModel.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import SwiftUI

@Observable
class SessionChartViewModel {
    
    enum ChartPeriod: Int, CaseIterable, Identifiable {
        case day = 1,
        threeDays = 3
        var id: Int { rawValue }
    }
    
    struct ChartBar: Identifiable {
        let id = UUID()
        let position: Date
        let baseMinutes, extraMinutes: Double
        let baseColor, extraColor: Color
        let width: Double
    }
    
    var selectedPeriod: ChartPeriod = .day {
        didSet { updateChartData() }
    }
    
    // MARK: - X-Axis Properties
    var xAxisSegmentCenter: [Date] = []
    var xAxisSegmentLabels: [String] = []
    var visibleXAxisRange: ClosedRange<Date> = Date()...Date()
    
    // MARK: - Y-Axis Properties
    var visibleYAxisRange: ClosedRange<Double> = 0...0
    var yAxisGridStep: Double = 0
    
    // MARK: - Chart Data
    var chartBars: [ChartBar] = []
    
    private let calendar = Calendar.current
    private let sessions = testSessionsData
    private let sittingExercisingSpacing: TimeInterval = ChartConfig.secondsInHour * 0.5
    
    init() {
        updateChartData()
    }
    
    private func updateChartData() {
        let data = computeAggregatedData()
        // centers = [15 october 12:00, 16 october 12:00, 17 october 12:00]
        let centers = Array(Set(data.map { $0.periodCenterDate })).sorted()
        
        let baseDate = Date.distantPast
        let spacing: TimeInterval = selectedPeriod == .day
            ? ChartConfig.secondsInHour * 2
            : ChartConfig.secondsInHour * 4
        
        // MARK: - X-Axis Setup - Create artificial positions
        xAxisSegmentCenter = []

        for i in 0..<centers.count {
            let artificialTimeInterval = Double(i) * spacing
            let artificialPosition = baseDate.addingTimeInterval(artificialTimeInterval)
            xAxisSegmentCenter.append(artificialPosition)
        }
        
        xAxisSegmentLabels = centers.map { center in
            selectedPeriod == .day ? formatXAxisTimeRange(for: center) : formatXAxisWeekday(for: center)
        }
        
        setupVisibleXAxisRange(centers: xAxisSegmentCenter)
        setupYAxisRangeAndGrid()
        chartBars = createBars(from: data, centers: centers)
    }
    
    // MARK: - X-Axis Methods
    private func setupVisibleXAxisRange(centers: [Date]) {
        guard let first = centers.first, let last = centers.last else { return }
        let padding = sittingExercisingSpacing * 2
        visibleXAxisRange = first.addingTimeInterval(-padding)...last.addingTimeInterval(padding)
    }
    
    private func calculateXPositionWithOffset(for item: AggregatedData, centers: [Date]) -> Date {
        guard let index = centers.firstIndex(of: item.periodCenterDate) else {
            // (of: 15 october 12:00) = 0
            // (of: 16 october 12:00) = 1
            return item.periodCenterDate
        }
        // 00:00 ± 30 min
        // 04:00 ± 30 min
        let offset = item.activityType == .sitting ? -sittingExercisingSpacing : sittingExercisingSpacing
        return xAxisSegmentCenter[index].addingTimeInterval(offset)
    }
    
    private func formatXAxisTimeRange(for centerDate: Date) -> String {
        let hour = calendar.component(.hour, from: centerDate) - 1 // 13 - 1 = 12 / 15 - 1 = 14
        return "\(hour)-\(hour + ChartConfig.segmentHours)" // 12 + 2 = 14 / 14 + 2 = 16
    }
    
    private func formatXAxisWeekday(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
    
    // MARK: - Y-Axis Methods
    private func setupYAxisRangeAndGrid() {
        visibleYAxisRange = 0...calculateMaxYValue()
        yAxisGridStep = calculateYAxisGridStep()
    }
    
    private func calculateMaxYValue() -> Double {
        let data = computeAggregatedData()
        let maxMinutes = data.map { $0.baseMinutes + $0.extraMinutes }.max() ?? 0
        return max(maxMinutes, ChartConfig.Axis.defaultPeriodInMinutes) * ChartConfig.Axis.YAxis.maxScaleFactor
    }
    
    private func calculateYAxisGridStep() -> Double {
        let hour: Double = 60
        let maxValue = calculateMaxYValue()
        
        switch maxValue {
        case ...hour: return ChartConfig.Axis.GridStep.small.rawValue
        case ...(hour * ChartConfig.Axis.YAxis.mediumThreshold): return ChartConfig.Axis.GridStep.medium.rawValue
        case ...(hour * ChartConfig.Axis.YAxis.largeThreshold): return ChartConfig.Axis.GridStep.large.rawValue
        default: return max(maxValue / ChartConfig.Axis.YAxis.stepDivisor, hour)
        }
    }
    
    private func filterSessions() -> [M_Session] {
        let now = Date()
        let offset = selectedPeriod == .day ? 0 : ChartConfig.threeDaysOffset
        let start = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
        return sessions.filter { $0.createdAt >= start && $0.createdAt <= now }
    }
    
    private func createDataEntries(for sessions: [M_Session], center: Date) -> [AggregatedData] {
        let sittingBase = Double(sessions.reduce(0) { $0 + $1.sittingOverall })
        let sittingExtra = Double(sessions.reduce(0) { $0 + $1.sittingOvertime })
        let exercisingBase = Double(sessions.reduce(0) { $0 + $1.exercisingOverall })
        let exercisingExtra = Double(sessions.reduce(0) { $0 + $1.exercisingOvertime })
        
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
    
    private func createBars(from data: [AggregatedData], centers: [Date]) -> [ChartBar] {
        let width = ChartConfig.barWidth(for: data.count)
        
        return data.map { item in
            let position = calculateXPositionWithOffset(for: item, centers: centers)
            let colors = getColors(for: item.activityType)
            
            return ChartBar(
                position: position,
                baseMinutes: item.baseMinutes,
                extraMinutes: item.extraMinutes,
                baseColor: colors.base,
                extraColor: colors.extra,
                width: width
            )
        }
    }
    
    private func getColors(for type: AggregatedData.ActivityType) -> (base: Color, extra: Color) {
        switch type {
        case .sitting:
            return (ChartConfig.Colors.sittingBase, ChartConfig.Colors.sittingExtra)
        case .exercising:
            return (ChartConfig.Colors.exercisingBase, ChartConfig.Colors.exercisingExtra)
        }
    }
}

// Aggregate data
private extension SessionChartViewModel {
    func computeAggregatedData() -> [AggregatedData] {
        let filtered = filterSessions()
        return selectedPeriod == .day
        ? aggregateBySegments(sessions: filtered)
        : aggregateByDays(sessions: filtered)
    }
    
    func aggregateBySegments(sessions: [M_Session]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        
        // Step 1: Group sessions by 2-hour intervals manually
        var groupedSessionsByTimeInterval: [Int: [M_Session]] = [:]
        
        for session in sessions {
            let hour = calendar.component(.hour, from: session.createdAt)
            let intervalIndex = hour / ChartConfig.segmentHours
            let intervalStartHour = intervalIndex * ChartConfig.segmentHours
            
            // Create empty array for this key if it doesn't exist
            if groupedSessionsByTimeInterval[intervalStartHour] == nil {
                groupedSessionsByTimeInterval[intervalStartHour] = []
            }
            // Add session to the array for this interval
            groupedSessionsByTimeInterval[intervalStartHour]!.append(session)
        }
        
        var aggregatedResults: [AggregatedData] = []
        
        // Step 2: Process each group of sessions
        for (intervalStartHour, groupedSessions) in groupedSessionsByTimeInterval.sorted(by: { $0.key < $1.key }) {
            
            // Calculate interval center (middle of 2-hour range)
            let intervalCenter = calendar.date(byAdding: .hour, value: intervalStartHour + 1, to: today)!
            
            // Step 3: Create aggregated data for this group
            let dataForThisInterval = createDataEntries(
                for: groupedSessions,
                center: intervalCenter
            )
            
            aggregatedResults.append(contentsOf: dataForThisInterval)
        }
        
        return aggregatedResults
    }

    func aggregateByDays(sessions: [M_Session]) -> [AggregatedData] {
        // Step 1: Group sessions by days manually
        var groupedSessionsByDay: [Date: [M_Session]] = [:]
        
        for session in sessions {
            // dayStart = 00:00 of each day
            let dayStart = calendar.startOfDay(for: session.createdAt)
            
            // Create empty array for this day if it doesn't exist
            if groupedSessionsByDay[dayStart] == nil {
                groupedSessionsByDay[dayStart] = []
            }
            // Add session to the array for this day
            groupedSessionsByDay[dayStart]!.append(session)
        }
        
        var aggregatedResults: [AggregatedData] = []
        
        // Step 2: Process each day group of sessions
        for (dayStart, groupedSessions) in groupedSessionsByDay.sorted(by: { $0.key < $1.key }) {
            
            // Calculate day center (12:00 - noon)
            let dayCenter = calendar.date(byAdding: .hour, value: ChartConfig.dayCenterHour, to: dayStart)!
            
            // Step 3: Create aggregated data for this day
            let dataForThisDay = createDataEntries(
                for: groupedSessions,
                center: dayCenter
            )
            
            aggregatedResults.append(contentsOf: dataForThisDay)
        }
        
        return aggregatedResults
    }
}
