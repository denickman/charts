//
//  SessionChartViewModel.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

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
        case day = 1
        case threeDays = 3
        var id: Int { rawValue }
    }
    
    struct ChartBar: Identifiable {
        let id = UUID()
        let mappedPositionDate: Date
        let baseMinutes: Double
        let extraMinutes: Double
        let baseColor: Color
        let extraColor: Color
        let width: Double
    }
    
    var selectedPeriod: ChartPeriod = .day {
        didSet {
            updateChartData()
        }
    }
    
    var chartBars: [ChartBar] = []
    var axisMarkCenters: [Date] = []  // Mapped centers for axis marks
    var axisLabels: [String] = []  // Labels for axis marks
    var xAxisDomain: ClosedRange<Date> = Date()...Date()
    var yAxisDomain: ClosedRange<Double> = 0...0
    var yAxisGridStep: Double = 0
    var totalSittingMinutes: Double = 0
    var totalExercisingMinutes: Double = 0
    
    private var aggregatedData: [AggregatedData] = []
    private var periodCenterDates: [Date] = []  // Unique actual center dates from aggregated data
    private let calendar = Calendar.current
    private let sessions: [M_Session] = testSessionsData  // Or from real source
    
    private var barPositionOffset: TimeInterval { ChartConfig.secondsInHour * 0.5 }  // 30 min offset for side-by-side bars
    
    init() {
        updateChartData()
    }
    
    private func updateChartData() {
        aggregatedData = computeAggregatedData()
        periodCenterDates = Array(Set(aggregatedData.map { $0.periodCenterDate })).sorted()
        
        let baseDate = Date.distantPast
        let periodSpacing: TimeInterval = selectedPeriod == .day
            ? ChartConfig.secondsInHour * 3
            : ChartConfig.secondsInHour * ChartConfig.hoursInDay
        
        let mappedCenters = periodCenterDates.indices.map {
            baseDate.addingTimeInterval(Double($0) * periodSpacing)
        }
        
        axisMarkCenters = mappedCenters
        axisLabels = periodCenterDates.map { center in
            if selectedPeriod == .day {
                let startHour = calendar.component(.hour, from: center) - 1
                return "\(startHour)-\(startHour + ChartConfig.segmentHours)"
            }
            return center.formatted(.dateTime.weekday(.abbreviated))
        }
        
        if let minCenter = mappedCenters.first, let maxCenter = mappedCenters.last {
            let padding = barPositionOffset * 2
            xAxisDomain = minCenter.addingTimeInterval(-padding)...maxCenter.addingTimeInterval(padding)
        }
        
        yAxisDomain = 0...maxYAxisValue
        yAxisGridStep = computeYAxisGridStep()
        
        totalSittingMinutes = aggregatedData
            .filter { $0.activityType == .sitting }
            .reduce(0) { $0 + $1.baseMinutes + $1.extraMinutes }
        
        totalExercisingMinutes = aggregatedData
            .filter { $0.activityType == .exercising }
            .reduce(0) { $0 + $1.baseMinutes + $1.extraMinutes }
        
        let numberOfBars = aggregatedData.count
        let barWidth = ChartConfig.barWidth(for: numberOfBars)
        chartBars = aggregatedData.map { createChartBar(for: $0, with: barWidth) }
    }
    
    private func computeAggregatedData() -> [AggregatedData] {
        let filteredSessions = filterSessionsByPeriod()
        switch selectedPeriod {
        case .day:
            return aggregateByTwoHourSegments(sessions: filteredSessions)
        case .threeDays:
            return aggregateByDays(sessions: filteredSessions)
        }
    }
    
    private func filterSessionsByPeriod() -> [M_Session] {
        let now = Date()
        let offset = selectedPeriod == .day ? 0 : ChartConfig.threeDaysOffset
        let startDate = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
        return sessions.filter { $0.createdAt >= startDate && $0.createdAt <= now }
    }
    
    private func aggregateByTwoHourSegments(sessions: [M_Session]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let grouped = Dictionary(grouping: sessions) { session in
            let hour = calendar.component(.hour, from: session.createdAt)
            return (hour / ChartConfig.segmentHours) * ChartConfig.segmentHours
        }
        
        var result: [AggregatedData] = []
        for (segmentStartHour, segmentSessions) in grouped.sorted(by: { $0.key < $1.key }) {
            let sittingBase = Double(segmentSessions.reduce(0) { $0 + $1.sittingOverall })
            let sittingExtra = Double(segmentSessions.reduce(0) { $0 + $1.sittingOvertime })
            let exercisingBase = Double(segmentSessions.reduce(0) { $0 + $1.exercisingOverall })
            let exercisingExtra = Double(segmentSessions.reduce(0) { $0 + $1.exercisingOvertime })
            
            let segmentCenter = calendar.date(byAdding: .hour, value: segmentStartHour + 1, to: today)!
            
            if sittingBase + sittingExtra > 0 {
                result.append(AggregatedData(periodCenterDate: segmentCenter, activityType: .sitting, baseMinutes: sittingBase, extraMinutes: sittingExtra))
            }
            if exercisingBase + exercisingExtra > 0 {
                result.append(AggregatedData(periodCenterDate: segmentCenter, activityType: .exercising, baseMinutes: exercisingBase, extraMinutes: exercisingExtra))
            }
        }
        return result
    }
    
    private func aggregateByDays(sessions: [M_Session]) -> [AggregatedData] {
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.createdAt) }
        
        var result: [AggregatedData] = []
        for (dayStart, daySessions) in grouped.sorted(by: { $0.key < $1.key }) {
            let sittingBase = Double(daySessions.reduce(0) { $0 + $1.sittingOverall })
            let sittingExtra = Double(daySessions.reduce(0) { $0 + $1.sittingOvertime })
            let exercisingBase = Double(daySessions.reduce(0) { $0 + $1.exercisingOverall })
            let exercisingExtra = Double(daySessions.reduce(0) { $0 + $1.exercisingOvertime })
            
            let dayCenter = calendar.date(byAdding: .hour, value: ChartConfig.dayCenterHour, to: dayStart)!
            
            if sittingBase + sittingExtra > 0 {
                result.append(AggregatedData(periodCenterDate: dayCenter, activityType: .sitting, baseMinutes: sittingBase, extraMinutes: sittingExtra))
            }
            if exercisingBase + exercisingExtra > 0 {
                result.append(AggregatedData(periodCenterDate: dayCenter, activityType: .exercising, baseMinutes: exercisingBase, extraMinutes: exercisingExtra))
            }
        }
        return result
    }
    
    private func mappedBarPosition(for data: AggregatedData) -> Date {
        if let index = periodCenterDates.firstIndex(of: data.periodCenterDate) {
            let mappedCenter = axisMarkCenters[index]
            let offset: TimeInterval = data.activityType == .sitting ? -barPositionOffset : barPositionOffset
            return mappedCenter.addingTimeInterval(offset)
        }
        return data.periodCenterDate
    }
    
    private func createChartBar(for data: AggregatedData, with width: Double) -> ChartBar {
        let (baseColor, extraColor) = colors(for: data.activityType)
        return ChartBar(
            mappedPositionDate: mappedBarPosition(for: data),
            baseMinutes: data.baseMinutes,
            extraMinutes: data.extraMinutes,
            baseColor: baseColor,
            extraColor: extraColor,
            width: width
        )
    }
    
    private func colors(for type: AggregatedData.ActivityType) -> (base: Color, extra: Color) {
        switch type {
        case .sitting:
            return (ChartConfig.Colors.sittingBase, ChartConfig.Colors.sittingExtra)
        case .exercising:
            return (ChartConfig.Colors.exercisingBase, ChartConfig.Colors.exercisingExtra)
        }
    }
    
    private var maxYAxisValue: Double {
        let maxValue = aggregatedData.map { $0.baseMinutes + $0.extraMinutes }.max() ?? 0
        return max(maxValue, ChartConfig.Axis.defaultPeriodInMinutes) * ChartConfig.Axis.YAxis.yAxisMaxScaleFactor
    }
    
    private func computeYAxisGridStep() -> Double {
        let oneHourInMinutes: Double = 60.0
        if maxYAxisValue <= oneHourInMinutes {
            return ChartConfig.Axis.GridStep.small.rawValue
        } else if maxYAxisValue <= oneHourInMinutes * ChartConfig.Axis.YAxis.mediumGridThresholdHours {
            return ChartConfig.Axis.GridStep.medium.rawValue
        } else if maxYAxisValue <= oneHourInMinutes * ChartConfig.Axis.YAxis.largeGridThresholdHours {
            return ChartConfig.Axis.GridStep.large.rawValue
        } else {
            let roughStep = maxYAxisValue / ChartConfig.Axis.YAxis.yAxisStepDivisor
            return max(roughStep.rounded(), oneHourInMinutes)
        }
    }
}
