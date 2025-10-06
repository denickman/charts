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
    
    enum Constants {
        static let defaultBarWidth: CGFloat = 14.0
        static let minBarWidth: CGFloat = 4.0
        static let maxBarWidth: CGFloat = 16.0
        static let defaultPeriodInMinutes: Double = 60.0
        
        enum Time {
            static let secondsInHour: TimeInterval = 3600
            static let minutesInHour: Double = 60.0
            static let hoursInDay: Double = 24.0
            static let daysInWeek: Double = 7.0
            static let monthsInHalfYear: Int = 6
            static let monthsInYear: Int = 12
        }
        
        enum BarWidth {
            static let lowDataThreshold: Int = 8
            static let mediumDataThreshold: Int = 16
            static let yearWidthMultiplier: Double = 1.2
        }
        
        enum YAxis {
            static let maxMultiplier: Double = 1.1
            static let denseGridStep: Double = 10
            static let normalGridStep: Double = 15
            static let sparseGridStep: Double = 30
            
            static let normalGridThreshold: Double = 2
            static let sparseGridThreshold: Double = 4
            static let autoCalculationDivisor: Double = 4
        }
        
        enum DateOffsets {
            static let threeDays: Int = -2
            static let week: Int = -6
            static let month: Int = -29
            static let halfYearMonth: Int = -5
            static let dayCenterHour: Int = 12
            static let yearCenterDays: Int = 15
            static let yearTimeOffsetDays: Double = 7.5
        }
        
        enum TimeOffsets {
            static let weekHours: Double = 4
            static let monthHours: Double = 6
            static let halfYearDays: Int = 1
        }
        
        enum DataRanges {
            static let dayHours: [Int] = [0, 6, 12, 18]
            static let threeDaysRange: ClosedRange<Int> = -2...0
            static let weekRange: ClosedRange<Int> = -6...0
            static let monthWeeks: Int = 5
            static let weekDaysInterval: Int = 7
        }
    }
    
    enum ChartPeriod: String, CaseIterable {
        case day = "1"
        case threeDays = "3"
        case week = "7"
        case month = "30"
        case halfYear = "180"
        case year = "365"
    }
 
    var selectedPeriod: ChartPeriod = .day
    
    // MARK: - Computed Properties

    var chartData: ChartData {
        switch selectedPeriod {
        case .day, .threeDays:
            return .sessionData(filteredData)
        case .week, .month, .halfYear, .year:
            return .aggregatedData(aggregatedData)
        }
    }

    var aggregatedData: [AggregatedData] {
        let currentStrategy = DataAggregationStrategyFactory.create(for: selectedPeriod)
        return currentStrategy.getAggregateData(from: sessionsData)
    }
    
    // TODO: - Temporary
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
        let maxValue = maxYValue * Constants.YAxis.maxMultiplier
        let oneHour = Constants.Time.minutesInHour
        
        if maxValue <= oneHour {
            return Constants.YAxis.denseGridStep
        } else if maxValue <= oneHour * Constants.YAxis.normalGridThreshold {
            return Constants.YAxis.normalGridStep
        } else if maxValue <= oneHour * Constants.YAxis.sparseGridThreshold {
            return Constants.YAxis.sparseGridStep
        } else {
            let roughStep = maxValue / Constants.YAxis.autoCalculationDivisor
            let roundedStep = (roughStep / oneHour).rounded() * oneHour
            return max(roundedStep, oneHour)
        }
    }
    
    var maxYValue: Double {
        let maxValue = aggregatedData.map { $0.base + $0.extra }.max() ?? 0
        return max(maxValue, Constants.defaultPeriodInMinutes)
    }
    
    // TODO: - Temporary properties
    
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
        case .sitting: return .red
        case .exercising: return .green
        }
    }
    
    private func centerDate(for date: Date) -> Date {
        currentAxisStrategy.centerDate(for: date)
    }
    
    // TODO: - Temporary
    private func filterSessionsForLastDays(_ days: Int) -> [SessionData] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now)!
        
        return sessionsData.filter { session in
            session.sittingDate >= startDate && session.sittingDate <= now
        }
    }
}
