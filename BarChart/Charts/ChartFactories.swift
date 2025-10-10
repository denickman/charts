//
//  ChartFactories.swift
//  BarChart
//
//  Created by Denis Yaremenko on 06.10.2025.
//

import Foundation

struct StrategyFactory {
    static func createAxisStrategy(for period: ChartViewModel.ChartPeriod) -> AxisStrategy {
        switch period {
        case .day: return DayAxisStrategy()
        case .threeDays: return ThreeDaysAxisStrategy()
        }
    }
    
    static func createDataAggregator(for period: ChartViewModel.ChartPeriod) -> DataAggregator {
        switch period {
        case .day: return DayDataAggregator()
        case .threeDays: return ThreeDaysDataAggregator()
        }
    }
}
