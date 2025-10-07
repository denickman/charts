//
//  SessionChartViewModel.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import SwiftUI

@Observable
class SessionChartViewModel {
    
    enum ChartData {
        case sessionData([SessionData])
        case aggregatedData([AggregatedData])
    }
    
    enum ChartPeriod: Int, CaseIterable, Identifiable {
        case day = 1
        case threeDays = 3
        case week = 7
        case halfMonth = 15
        case month = 30
        case halfYear = 180
        case year = 365
        
        var id: Int { rawValue }
    }
    
    struct ChartBar: Identifiable {
        let id = UUID()
        let xValue: Date
        let baseHeight: Double
        let extraHeight: Double
        let baseColor: Color
        let extraColor: Color
        let width: Double
    }
    
    var chartBars: [ChartBar] {
        switch selectedPeriod {
        case .day, .threeDays:
            return filteredData.flatMap { session in
                [
                    createBar(for: session, type: .sitting),
                    createBar(for: session, type: .exercising)
                ]
            }
        default:
            return aggregatedData.map { createBar(for: $0) }
        }
    }
    
    private func createBar(for session: SessionData, type: AggregatedData.ActivityType) -> ChartBar {
        let (baseColor, extraColor) = barStyle(for: type, isExtra: true)
        let xValue = type == .sitting ? session.sittingDate : session.exercisingDate
        let baseHeight = type == .sitting ? session.sittingBase : session.exercisingBase
        let extraHeight = type == .sitting ? session.sittingOvertime : session.exercisingExtra
        
        return ChartBar(
            xValue: xValue,
            baseHeight: baseHeight,
            extraHeight: extraHeight,
            baseColor: baseColor,
            extraColor: extraColor,
            width: dynamicBarWidth
        )
    }
    
    private func createBar(for data: AggregatedData) -> ChartBar {
        let (baseColor, extraColor) = barStyle(for: data.activityType, isExtra: true)
        let adjustedDate = calculateBarPosition(for: data)
        
        return ChartBar(
            xValue: adjustedDate,
            baseHeight: data.base,
            extraHeight: data.extra,
            baseColor: baseColor,
            extraColor: extraColor,
            width: dynamicBarWidth
        )
    }
    
    var selectedPeriod: ChartPeriod = .day
    
    // MARK: - Computed Properties
    
    var chartData: ChartData {
        switch selectedPeriod {
        case .day, .threeDays:
            return .sessionData(filteredData)
        case .week, .halfMonth, .month, .halfYear, .year:
            return .aggregatedData(aggregatedData)
        }
    }
    
    var aggregatedData: [AggregatedData] {
        let currentStrategy = DataAggregationStrategyFactory.create(for: selectedPeriod)
        return currentStrategy.getAggregateData(from: sessionsData)
    }
    
    var filteredData: [SessionData] {
        switch selectedPeriod {
        case .day:
            return filterSessionsForLastDays(1)
        case .threeDays:
            return filterSessionsForLastDays(3)
        default:
            return []
        }
    }
    
    var xAxisValues: [Date] {
        currentAxisStrategy.xAxisValues
    }
    
    var chartYScaleDomain: ClosedRange<Double> {
        0...maxYValue
    }
    
    var xAxisDomain: ClosedRange<Date> {
        currentAxisStrategy.xAxisDomain
    }
    
    var xAxisLabelFormat: Date.FormatStyle {
        currentAxisStrategy.xAxisLabelFormat
    }
    
    var dynamicBarWidth: Double {
        currentAxisStrategy.dynamicBarWidth
    }
    
    var dynamicTimeOffset: TimeInterval {
        currentAxisStrategy.dynamicTimeOffset
    }
    
    // MARK: - Y-axis Calculations
    
    var yAxisGridLineInterval: Double {
        let oneHour = ChartConfig.Time.minutesInHour
        
        if maxYValue <= oneHour {
            return ChartConfig.Axis.YAxis.denseGridStep
        } else if maxYValue <= oneHour * ChartConfig.Axis.YAxis.normalGridThreshold {
            return ChartConfig.Axis.YAxis.normalGridStep
        } else if maxYValue <= oneHour * ChartConfig.Axis.YAxis.sparseGridThreshold {
            return ChartConfig.Axis.YAxis.sparseGridStep
        } else {
            let roughStep = maxYValue / ChartConfig.Axis.YAxis.autoCalculationDivisor
            let roundedStep = (roughStep / oneHour).rounded() * oneHour
            return max(roundedStep, oneHour)
        }
    }
    
    var maxYValue: Double {
        let maxValue = aggregatedData.map { $0.base + $0.extra }.max() ?? 0
        return max(maxValue, ChartConfig.Axis.defaultPeriodInMinutes) * ChartConfig.Axis.YAxis.maxMultiplier
    }
    
    var totalSitting: Double {
        aggregatedData
            .filter { $0.activityType == .sitting }
            .reduce(0) { $0 + $1.base + $1.extra }
    }
    
    var totalExercising: Double {
        aggregatedData
            .filter { $0.activityType == .exercising }
            .reduce(0) { $0 + $1.base + $1.extra }
    }
    
    private let sessionsData: [SessionData] = testSessionsData
    
    private var currentAxisStrategy: ChartAxisStrategy {
        AxisStrategyFactory.create(for: selectedPeriod)
    }
    
    // MARK: - Methods
    
    func calculateBarPosition(for data: AggregatedData) -> Date {
        let centerDate = centerDate(for: data.date)
        let timeOffset: TimeInterval = data.activityType == .sitting ?
            -dynamicTimeOffset : dynamicTimeOffset
        return centerDate.addingTimeInterval(timeOffset)
    }
    
    func barColor(for activityType: AggregatedData.ActivityType) -> Color {
        switch activityType {
        case .sitting: return ChartConfig.Colors.sittingExtra
        case .exercising: return ChartConfig.Colors.exercisingExtra
        }
    }
    
    private func centerDate(for date: Date) -> Date {
        currentAxisStrategy.centerDate(for: date)
    }
    
    func barStyle(for type: AggregatedData.ActivityType, isExtra: Bool) -> (base: Color, extra: Color) {
        switch type {
        case .sitting:
            return (ChartConfig.Colors.sittingBase, ChartConfig.Colors.sittingExtra)
        case .exercising:
            return (ChartConfig.Colors.exercisingBase, ChartConfig.Colors.exercisingExtra)
        }
    }
    
    private func filterSessionsForLastDays(_ days: Int) -> [SessionData] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now)!
        
        return sessionsData.filter { session in
            session.sittingDate >= startDate && session.sittingDate <= now
        }
    }
}

extension SessionChartViewModel {
    struct AxisConfiguration {
        let values: [Date]
        let labelFormat: Date.FormatStyle
        let yAxisInterval: Double
    }
    
    var axisConfiguration: AxisConfiguration {
        AxisConfiguration(
            values: xAxisValues,
            labelFormat: xAxisLabelFormat,
            yAxisInterval: yAxisGridLineInterval
        )
    }
}
