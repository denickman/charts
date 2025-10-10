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
        case day = 1, threeDays = 3
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
    
    // MARK: - X-Axis Properties (Ось X - временная ось)
    var xAxisCenters: [Date] = []          // Искусственные центры для оси X
    var xAxisLabels: [String] = []         // Подписи для оси X
    var xAxisRange: ClosedRange<Date> = Date()...Date()  // Диапазон оси X
    
    // MARK: - Y-Axis Properties (Ось Y - ось минут)
    var yAxisRange: ClosedRange<Double> = 0...0          // Диапазон оси Y
    var yAxisGridStep: Double = 0          // Шаг сетки для оси Y
    
    // MARK: - Chart Data
    var chartBars: [ChartBar] = []         // Данные для столбцов графика
    
    private let calendar = Calendar.current
    private let sessions = testSessionsData
    private let sittingExercisingSpacing: TimeInterval = ChartConfig.secondsInHour * 0.5
    
    init() {
        updateChartData()
    }
    
    private func updateChartData() {
        let data = computeAggregatedData()
        let centers = Array(Set(data.map { $0.periodCenterDate })).sorted()
        
        let baseDate = Date.distantPast
        // Уменьшаем spacing для более компактного расположения
        let spacing: TimeInterval = selectedPeriod == .day
            ? ChartConfig.secondsInHour * 2  // было 3, теперь 2 часа
            : ChartConfig.secondsInHour * 4  // было 24, теперь 8 часов
        
        // MARK: - X-Axis Setup (Настройка оси X)
        xAxisCenters = centers.indices.map {
            baseDate.addingTimeInterval(Double($0) * spacing)
        }
        
        xAxisLabels = centers.map { center in
            selectedPeriod == .day ? formatXAxisTimeRange(for: center) : formatXAxisWeekday(for: center)
        }
        
        setupXAxisRange(centers: xAxisCenters)
        setupYAxisRangeAndGrid()
        chartBars = createBars(from: data, centers: centers)
    }
    
    // MARK: - X-Axis Methods (Методы для оси X)
    private func setupXAxisRange(centers: [Date]) {
        guard let first = centers.first, let last = centers.last else { return }
        let padding = sittingExercisingSpacing * 2
        xAxisRange = first.addingTimeInterval(-padding)...last.addingTimeInterval(padding)
    }
    
    private func calculateXPosition(for item: AggregatedData, centers: [Date]) -> Date {
        guard let index = centers.firstIndex(of: item.periodCenterDate) else {
            return item.periodCenterDate
        }
        let offset = item.activityType == .sitting ? -sittingExercisingSpacing : sittingExercisingSpacing
        return xAxisCenters[index].addingTimeInterval(offset)
    }
    
    private func formatXAxisTimeRange(for date: Date) -> String {
        let hour = calendar.component(.hour, from: date) - 1
        return "\(hour)-\(hour + ChartConfig.segmentHours)"
    }
    
    private func formatXAxisWeekday(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
    
    // MARK: - Y-Axis Methods (Методы для оси Y)
    private func setupYAxisRangeAndGrid() {
        yAxisRange = 0...calculateMaxYValue()
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
            let position = calculateXPosition(for: item, centers: centers)
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
        let grouped = Dictionary(grouping: sessions) { session in
            let hour = calendar.component(.hour, from: session.createdAt)
            return (hour / ChartConfig.segmentHours) * ChartConfig.segmentHours
        }
        
        var result: [AggregatedData] = []
        for (segmentStartHour, segmentSessions) in grouped.sorted(by: { $0.key < $1.key }) {
            let segmentCenter = calendar.date(byAdding: .hour, value: segmentStartHour + 1, to: today)!
            result.append(contentsOf: createDataEntries(for: segmentSessions, center: segmentCenter))
        }
        return result
    }
    
    func aggregateByDays(sessions: [M_Session]) -> [AggregatedData] {
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.createdAt) }
        
        var result: [AggregatedData] = []
        for (day, daySessions) in grouped.sorted(by: { $0.key < $1.key }) {
            let dayCenter = calendar.date(byAdding: .hour, value: ChartConfig.dayCenterHour, to: day)!
            result.append(contentsOf: createDataEntries(for: daySessions, center: dayCenter))
        }
        return result
    }
}
