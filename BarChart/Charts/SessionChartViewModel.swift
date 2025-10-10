//
//  SessionChartViewModel.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import SwiftUI

@Observable
class ChartViewModel {
    enum ChartPeriod: CaseIterable {
        case day, threeDays
        
        var displayName: String {
            switch self {
            case .day: return "1 Day"
            case .threeDays: return "3 Days"
            }
        }
    }
    
    struct ChartBar: Identifiable {
        let id = UUID()
        let date: Date
        let base: Double
        let extra: Double
        let baseColor: Color  // Добавлено
        let extraColor: Color // Добавлено
        let width: Double
        let timeLabel: String?
    }
    
    var selectedPeriod: ChartPeriod = .day
    private let testData: [Session] = SampleData.sessions
    
    // Computed properties
    var chartData: [ChartData] {
        let aggregator = StrategyFactory.createDataAggregator(for: selectedPeriod)
        return aggregator.aggregate(testData)
    }
    
    var bars: [ChartBar] {
        let axisStrategy = StrategyFactory.createAxisStrategy(for: selectedPeriod)
        
        return chartData.map { data in
            let positionedDate = axisStrategy.calculateBarPosition(for: data)
            
            // Замени это:
            // let color = data.activityType == .sitting ? Color.red : Color.green
            
            // На это:
            let baseColor = Color.gray.opacity(0.8)
            let extraColor = data.activityType == .sitting ? Color.red.opacity(0.8) : Color.green.opacity(0.8)
            
            return ChartBar(
                date: positionedDate,
                base: data.base,
                extra: data.extra,
                baseColor: baseColor,   // Изменено
                extraColor: extraColor, // Изменено
                width: axisStrategy.barWidth,
                timeLabel: data.timeLabel
            )
        }
    }
    
    var axisConfig: AxisConfig {
        let axisStrategy = StrategyFactory.createAxisStrategy(for: selectedPeriod)
        return axisStrategy.getAxisConfiguration(for: chartData)
    }
    
    var totals: (sitting: Double, exercising: Double) {
        let sitting = chartData.filter { $0.activityType == .sitting }.reduce(0) { $0 + $1.total }
        let exercising = chartData.filter { $0.activityType == .exercising }.reduce(0) { $0 + $1.total }
        return (sitting, exercising)
    }
    
    var yAxisRange: ClosedRange<Double> {
        let maxValue = chartData.map { $0.total }.max() ?? 60
        return 0...max(maxValue * 1.1, 60)
    }
    
    var yAxisStep: Double {
        let range = yAxisRange.upperBound
        if range <= 60 { return 10 }
        else if range <= 120 { return 15 }
        else { return 30 }
    }
}
