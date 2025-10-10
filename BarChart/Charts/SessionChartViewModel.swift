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
        let xValue: Date  // Mapped position
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
    var periodCenters: [Date] = []  // Для AxisMarks (mapped centers)
    var periodLabels: [String] = []  // Лейблы для периодов
    var xAxisDomain: ClosedRange<Date> = Date()...Date()
    var chartYScaleDomain: ClosedRange<Double> = 0...0
    var yAxisGridLineInterval: Double = 0
    var totalSitting: Double = 0
    var totalExercising: Double = 0
    
    private var aggregatedData: [AggregatedData] = []
    private let calendar = Calendar.current
    private let sessions: [M_Session] = testSessionsData  // Или из реального источника
    
    private var dynamicTimeOffset: TimeInterval { ChartConfig.Time.secondsInHour * 0.5 }  // 30 мин для сдвига
    private var dynamicBarWidth: Double {
        selectedPeriod == .day ? ChartConfig.Bar.defaultWidth : ChartConfig.Bar.minWidth
    }
    
    init() {
        updateData()
    }
    
    private func updateData() {
        aggregatedData = computeAggregatedData()
        let (actualCenters, labels, mappedCenters) = computePeriods()
        periodCenters = mappedCenters
        periodLabels = labels
        
        if let minCenter = mappedCenters.first, let maxCenter = mappedCenters.last {
            let padding = dynamicTimeOffset * 2
            xAxisDomain = minCenter.addingTimeInterval(-padding)...maxCenter.addingTimeInterval(padding)
        }
        
        chartYScaleDomain = 0...maxYValue
        yAxisGridLineInterval = computeYAxisInterval()
        
        totalSitting = aggregatedData.filter { $0.activityType == .sitting }.reduce(0) { $0 + $1.base + $1.extra }
        totalExercising = aggregatedData.filter { $0.activityType == .exercising }.reduce(0) { $0 + $1.base + $1.extra }
        
        chartBars = aggregatedData.map { createBar(for: $0) }
    }
    
    private func computeAggregatedData() -> [AggregatedData] {
        let filteredSessions = filterSessions()
        switch selectedPeriod {
        case .day:
            return aggregateByHourBins(sessions: filteredSessions)
        case .threeDays:
            return aggregateByDays(sessions: filteredSessions)
        }
    }
    
    private func filterSessions() -> [M_Session] {
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: selectedPeriod == .day ? -1 : ChartConfig.DateOffsets.threeDays, to: now)!
        return sessions.filter { $0.createdAt >= startDate && $0.createdAt <= now }
    }
    
    private func aggregateByHourBins(sessions: [M_Session]) -> [AggregatedData] {
        let today = calendar.startOfDay(for: Date())
        let grouped = Dictionary(grouping: sessions) { session in
            let hour = calendar.component(.hour, from: session.createdAt)
            return (hour / ChartConfig.DataRanges.binHours) * ChartConfig.DataRanges.binHours
        }
        
        var result: [AggregatedData] = []
        for (binStartHour, binSessions) in grouped.sorted(by: { $0.key < $1.key }) {
            let sittingBase = Double(binSessions.reduce(0) { $0 + $1.sittingOverall })
            let sittingExtra = Double(binSessions.reduce(0) { $0 + $1.sittingOvertime })
            let exercisingBase = Double(binSessions.reduce(0) { $0 + $1.exercisingOverall })
            let exercisingExtra = Double(binSessions.reduce(0) { $0 + $1.exercisingOvertime })
            
            if sittingBase + sittingExtra + exercisingBase + exercisingExtra > 0 {
                let binCenter = calendar.date(byAdding: .hour, value: binStartHour + 1, to: today)!  // Центр бина
                result.append(AggregatedData(date: binCenter, activityType: .sitting, base: sittingBase, extra: sittingExtra))
                result.append(AggregatedData(date: binCenter, activityType: .exercising, base: exercisingBase, extra: exercisingExtra))
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
            
            if sittingBase + sittingExtra + exercisingBase + exercisingExtra > 0 {
                let dayCenter = calendar.date(byAdding: .hour, value: ChartConfig.DateOffsets.dayCenterHour, to: dayStart)!
                result.append(AggregatedData(date: dayCenter, activityType: .sitting, base: sittingBase, extra: sittingExtra))
                result.append(AggregatedData(date: dayCenter, activityType: .exercising, base: exercisingBase, extra: exercisingExtra))
            }
        }
        return result
    }
    
    private func computePeriods() -> (actualCenters: [Date], labels: [String], mappedCenters: [Date]) {
        let uniqueActualCenters = Set(aggregatedData.map { $0.date }).sorted()
        let baseDate = Date.distantPast
        let slotInterval: TimeInterval = selectedPeriod == .day ? ChartConfig.Time.secondsInHour * 3 : ChartConfig.Time.secondsInHour * ChartConfig.Time.hoursInDay  // 3 часа для дня, 1 день для 3 дней
        
        let mappedCenters = uniqueActualCenters.indices.map { index in
            baseDate.addingTimeInterval(Double(index) * slotInterval)
        }
        
        let labels: [String] = uniqueActualCenters.map { center in
            if selectedPeriod == .day {
                let hour = calendar.component(.hour, from: center) - 1  // binStart = center - 1 hour
                return "\(hour)-\(hour + ChartConfig.DataRanges.binHours)"
            } else {
                return center.formatted(.dateTime.weekday(.abbreviated))
            }
        }
        
        return (uniqueActualCenters, labels, mappedCenters)
    }
    
    private func mappedBarPosition(for data: AggregatedData) -> Date {
        let (actualCenters, _, mappedCenters) = computePeriods()
        if let index = actualCenters.firstIndex(of: data.date) {
            let mappedCenter = mappedCenters[index]
            let offset: TimeInterval = data.activityType == .sitting ? -dynamicTimeOffset : dynamicTimeOffset
            return mappedCenter.addingTimeInterval(offset)
        }
        return data.date
    }
    
    private func createBar(for data: AggregatedData) -> ChartBar {
        let (baseColor, extraColor) = colors(for: data.activityType)
        return ChartBar(
            xValue: mappedBarPosition(for: data),
            baseHeight: data.base,
            extraHeight: data.extra,
            baseColor: baseColor,
            extraColor: extraColor,
            width: dynamicBarWidth
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
    
    private func computeYAxisInterval() -> Double {
        let oneHour = ChartConfig.Time.secondsInHour / 60  // minutes
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
