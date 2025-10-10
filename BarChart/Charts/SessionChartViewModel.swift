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
        let barDate: Date  // Mapped position
        let baseHeight: Double
        let extraHeight: Double
        let baseColor: Color
        let extraColor: Color
        let width: Double
    }
    
    var selectedPeriod: ChartPeriod = .day {
        didSet {
            updateData()
        }
    }
    
    var chartBars: [ChartBar] = []
    var axisCenters: [Date] = []  // For AxisMarks (mapped centers)
    var axisLabels: [String] = []  // Labels for periods
    var xAxisDomain: ClosedRange<Date> = Date()...Date()
    var yAxisDomain: ClosedRange<Double> = 0...0
    var yAxisStep: Double = 0
    var totalSittingMinutes: Double = 0
    var totalExercisingMinutes: Double = 0
    
    private var aggregatedData: [AggregatedData] = []
    private let calendar = Calendar.current
    private let sessions: [M_Session] = testSessionsData  // Or from real source
    
    private var barOffset: TimeInterval { ChartConfig.secondsInHour * 0.5 }  // 30 min for offset
    private var barWidth: Double {
        selectedPeriod == .day ? ChartConfig.Bar.defaultWidth : ChartConfig.Bar.minWidth
    }
    
    init() {
        updateData()
    }
    
    private func updateData() {
        aggregatedData = computeAggregatedData()
        let (dataCenters, labels, mappedCenters) = computePeriods()
        axisCenters = mappedCenters
        axisLabels = labels
        
        if let minCenter = mappedCenters.first, let maxCenter = mappedCenters.last {
            let padding = barOffset * 2
            xAxisDomain = minCenter.addingTimeInterval(-padding)...maxCenter.addingTimeInterval(padding)
        }
        
        yAxisDomain = 0...maxYValue
        yAxisStep = computeYAxisStep()
        
        totalSittingMinutes = aggregatedData.filter { $0.activityType == .sitting }.reduce(0) { $0 + $1.base + $1.extra }
        totalExercisingMinutes = aggregatedData.filter { $0.activityType == .exercising }.reduce(0) { $0 + $1.base + $1.extra }
        
        chartBars = aggregatedData.map { createBar(for: $0) }
    }
    
    private func computeAggregatedData() -> [AggregatedData] {
        let filteredSessions = filterSessions()
        switch selectedPeriod {
        case .day:
            return aggregateByHourSegments(sessions: filteredSessions)
        case .threeDays:
            return aggregateByDays(sessions: filteredSessions)
        }
    }
    
    private func filterSessions() -> [M_Session] {
        let now = Date()
        let offset = selectedPeriod == .day ? 0 : ChartConfig.threeDaysOffset
        let startDate = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
        return sessions.filter { $0.createdAt >= startDate && $0.createdAt <= now }
    }
    
    private func aggregateByHourSegments(sessions: [M_Session]) -> [AggregatedData] {
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
            
            guard sittingBase + sittingExtra + exercisingBase + exercisingExtra > 0 else { continue }
            
            let segmentCenter = calendar.date(byAdding: .hour, value: segmentStartHour + 1, to: today)!
            result.append(AggregatedData(date: segmentCenter, activityType: .sitting, base: sittingBase, extra: sittingExtra))
            result.append(AggregatedData(date: segmentCenter, activityType: .exercising, base: exercisingBase, extra: exercisingExtra))
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
            
            guard sittingBase + sittingExtra + exercisingBase + exercisingExtra > 0 else { continue }
            
            let dayCenter = calendar.date(byAdding: .hour, value: ChartConfig.dayCenterHour, to: dayStart)!
            result.append(AggregatedData(date: dayCenter, activityType: .sitting, base: sittingBase, extra: sittingExtra))
            result.append(AggregatedData(date: dayCenter, activityType: .exercising, base: exercisingBase, extra: exercisingExtra))
        }
        return result
    }
    
    private func computePeriods() -> (dataCenters: [Date], labels: [String], mappedCenters: [Date]) {
        let dataCenters = Array(Set(aggregatedData.map { $0.date })).sorted()
        let baseDate = Date.distantPast
        let segmentSpacing: TimeInterval = selectedPeriod == .day ? ChartConfig.secondsInHour * 3 : ChartConfig.secondsInHour * ChartConfig.hoursInDay
        
        let mappedCenters = dataCenters.indices.map { baseDate.addingTimeInterval(Double($0) * segmentSpacing) }
        
        let labels: [String] = dataCenters.map { center in
            if selectedPeriod == .day {
                let startHour = calendar.component(.hour, from: center) - 1
                return "\(startHour)-\(startHour + ChartConfig.segmentHours)"
            }
            return center.formatted(.dateTime.weekday(.abbreviated))
        }
        
        return (dataCenters, labels, mappedCenters)
    }
    
    private func mappedBarPosition(for data: AggregatedData) -> Date {
        let (dataCenters, _, mappedCenters) = computePeriods()
        if let index = dataCenters.firstIndex(of: data.date) {
            let mappedCenter = mappedCenters[index]
            let offset: TimeInterval = data.activityType == .sitting ? -barOffset : barOffset
            return mappedCenter.addingTimeInterval(offset)
        }
        return data.date
    }
    
    private func createBar(for data: AggregatedData) -> ChartBar {
        let (baseColor, extraColor) = colors(for: data.activityType)
        return ChartBar(
            barDate: mappedBarPosition(for: data),
            baseHeight: data.base,
            extraHeight: data.extra,
            baseColor: baseColor,
            extraColor: extraColor,
            width: barWidth
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
    
    private var maxYValue: Double {
        let maxValue = aggregatedData.map { $0.base + $0.extra }.max() ?? 0
        return max(maxValue, ChartConfig.Axis.defaultPeriodInMinutes) * ChartConfig.Axis.YAxis.maxMultiplier
    }
    
    private func computeYAxisStep() -> Double {
        let oneHour: Double = 60.0
        if maxYValue <= oneHour {
            return ChartConfig.Axis.YAxis.denseGridStep
        } else if maxYValue <= oneHour * ChartConfig.Axis.YAxis.normalGridThreshold {
            return ChartConfig.Axis.YAxis.normalGridStep
        } else if maxYValue <= oneHour * ChartConfig.Axis.YAxis.sparseGridThreshold {
            return ChartConfig.Axis.YAxis.sparseGridStep
        } else {
            let roughStep = maxYValue / ChartConfig.Axis.YAxis.autoCalculationDivisor
            return max(roughStep.rounded(), oneHour)
        }
    }
}
