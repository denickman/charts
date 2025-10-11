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
    var artificialSegmentXAxisCenters: [Date] = []
    var xAxisSegmentLabels: [String] = []
    var visibleXAxisRange: ClosedRange<Date> = Date()...Date()
    
    // MARK: - Y-Axis Properties
    var visibleYAxisRange: ClosedRange<Double> = 0...0
    var yAxisGridStep: Double = 0
    
    // MARK: - Chart Data
    var chartBars: [ChartBar] = []
    
    private let calendar = Calendar.current
    private let sessions = testSessionsData
    private let spacingBetweeTwoBarsInSegment: TimeInterval = ChartConfig.secondsInHour * 0.5
    
    init() {
        updateChartData()
    }
    
    private func updateChartData() {
        let data = computeAggregatedData()
        // data = [
        //     AggregatedData(periodCenterDate: 13:00, sitting, 20, 10),
        //     AggregatedData(periodCenterDate: 13:00, exercising, 15, 5),
        //     AggregatedData(periodCenterDate: 15:00, sitting, 25, 15),
        //     AggregatedData(periodCenterDate: 15:00, exercising, 10, 5),
        //     AggregatedData(periodCenterDate: 19:00, sitting, 30, 10)
        // ]
        
        let realSegmentCenters = Array(Set(data.map { $0.periodCenterDate })).sorted()
        // data.map { $0.periodCenterDate } = [13:00, 13:00, 15:00, 15:00, 19:00]
        // Set(...) = {13:00, 15:00, 19:00} (unique values)
        // Array(...).sorted() = [13:00, 15:00, 19:00] ← real centers (not uniform)
        
        let baseDate = Date.distantPast
        // baseDate = January 1, 2000, 00:00
        
        let distanceBetweenSegmentCenters: TimeInterval = selectedPeriod == .day
            ? ChartConfig.secondsInHour * ChartConfig.Spacing.dayModeSpacingInHours
            : ChartConfig.secondsInHour * ChartConfig.Spacing.threeDaysModeSpacingInHours
        
        // MARK: - X-Axis Setup - Create artificial positions
        artificialSegmentXAxisCenters = []

        for i in 0..<realSegmentCenters.count {
            // realSegmentCenters = [13:00, 15:00, 19:00] (real segment centers with irregular spacing)
            // distanceBetweenSegmentCenters = 2 hours (for day mode) - fixed spacing for uniform display
            
            // Calculate offset for artificial position
            let artificialTimeInterval = Double(i) * distanceBetweenSegmentCenters
            // i=0 → 0 * 2 = 0 hours
            // i=1 → 1 * 2 = 2 hours
            // i=2 → 2 * 2 = 4 hours
            
            // Create artificial position from base date
            let artificialPosition = baseDate.addingTimeInterval(artificialTimeInterval)
            // i=0 → 00:00 + 0 = 00:00 (for 13:00 real data)
            // i=1 → 00:00 + 2 hours = 02:00 (for 15:00 real data)
            // i=2 → 00:00 + 4 hours = 04:00 (for 19:00 real data)
            
            // Add artificial position to array
            artificialSegmentXAxisCenters.append(artificialPosition)
            // Result: [00:00, 02:00, 04:00] - now evenly spaced
        }
        
        xAxisSegmentLabels = realSegmentCenters.map { realCenter in
            selectedPeriod == .day ? formatXAxisTimeRange(for: realCenter) : formatXAxisWeekday(for: realCenter)
        }
        
        setupVisibleXAxisRange(centers: artificialSegmentXAxisCenters)
        setupYAxisRangeAndGrid()
        chartBars = createBars(from: data, centers: realSegmentCenters)
    }
    
    // MARK: - X-Axis Methods
    private func setupVisibleXAxisRange(centers: [Date]) {
        guard let firstCenter = centers.first, let lastCenter = centers.last else { return }
        let axisPadding = spacingBetweeTwoBarsInSegment * ChartConfig.Spacing.visibleRangePaddingMultiplier
        visibleXAxisRange = firstCenter.addingTimeInterval(-axisPadding)...lastCenter.addingTimeInterval(axisPadding)
    }
    
    private func calculateBarPositionByOffsettingFromSegmentCenter(
        for item: AggregatedData,
        centers: [Date]
    ) -> Date {
        guard let index = centers.firstIndex(of: item.periodCenterDate) else {
            return item.periodCenterDate
        }
        let barOffsetFromCenter = item.activityType == .sitting ? -spacingBetweeTwoBarsInSegment : spacingBetweeTwoBarsInSegment
        // Для центра 13:00 (index=0): 00:00 ± 30min = 23:30 или 00:30
          // Оба бара остаются в пределах 2-часового диапазона 12-14!
        return artificialSegmentXAxisCenters[index].addingTimeInterval(barOffsetFromCenter)
    }
    
    private func formatXAxisTimeRange(for centerDate: Date) -> String {
        let segmentStartHour = calendar.component(.hour, from: centerDate) - 1 // 13 - 1 = 12 / 15 - 1 = 14
        return "\(segmentStartHour)-\(segmentStartHour + ChartConfig.segmentHours)" // 12 + 2 = 14 / 14 + 2 = 16
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
        let maxTotalMinutes = data.map { $0.baseMinutes + $0.extraMinutes }.max() ?? 0
        return max(maxTotalMinutes, ChartConfig.Axis.defaultPeriodInMinutes) * ChartConfig.Axis.YAxis.maxScaleFactor
    }
    
    private func calculateYAxisGridStep() -> Double {
        let oneHourInMinutes: Double = 60
        let maxYValue = calculateMaxYValue()
        
        switch maxYValue {
        case ...oneHourInMinutes: return ChartConfig.Axis.GridStep.small.rawValue
        case ...(oneHourInMinutes * ChartConfig.Axis.YAxis.mediumThreshold): return ChartConfig.Axis.GridStep.medium.rawValue
        case ...(oneHourInMinutes * ChartConfig.Axis.YAxis.largeThreshold): return ChartConfig.Axis.GridStep.large.rawValue
        default: return max(maxYValue / ChartConfig.Axis.YAxis.stepDivisor, oneHourInMinutes)
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
        let barWidth = ChartConfig.barWidth(for: data.count)
        
        return data.map { item in
            let position = calculateBarPositionByOffsettingFromSegmentCenter(for: item, centers: centers)
            let colors = getColors(for: item.activityType)
            
            return ChartBar(
                position: position,
                baseMinutes: item.baseMinutes,
                extraMinutes: item.extraMinutes,
                baseColor: colors.base,
                extraColor: colors.extra,
                width: barWidth
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
          
          let strategy: DataAggregationStrategy = selectedPeriod == .day
              ? IntraDayAggregationStrategy()
              : DailyAggregationStrategy()
          
          return strategy.aggregate(sessions: filtered, calendar: calendar)
      }
}
