//
//  ChartFactories.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation


struct AxisStrategyFactory {
    static func create(for period: SessionChartViewModel.ChartPeriod) -> ChartAxisStrategy {
        switch period {
        case .day: return DayXAxisStrategy()
        case .threeDays: return ThreeDaysXAxisStrategy()
        }
    }
}

struct DataAggregationStrategyFactory {
    static func create(for period: SessionChartViewModel.ChartPeriod) -> DataAggregationStrategy {
        switch period {
        case .day: return DayDataAggregationStrategy()
        case .threeDays: return ThreeDaysDataAggregationStrategy()
        }
    }
}
