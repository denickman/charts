////
////  ChartView.swift
////  BarChart
////
////  Created by Denis Yaremenko on 29.09.2025.
////
///
// MARK: - Simplified View

import SwiftUI
import Charts


struct ChartView: View {
    @State private var viewModel = ChartViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            periodPicker
            totalsView
            chart
        }
    }
    
    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(ChartViewModel.ChartPeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    private var totalsView: some View {
        VStack {
            Text("Sitting: \(Int(viewModel.totals.sitting)) min")
            Text("Exercising: \(Int(viewModel.totals.exercising)) min")
        }
        .font(.headline)
    }
    
    private var chart: some View {
        Chart {
              ForEach(viewModel.bars) { bar in
                  // Базовая часть (серая)
                  BarMark(
                      x: .value("Time", bar.date),
                      y: .value("Minutes", bar.base),
                      width: .fixed(bar.width)
                  )
                  .foregroundStyle(bar.baseColor) // Серая база
                  
                  // Дополнительная часть (красная/зеленая)
                  BarMark(
                      x: .value("Time", bar.date),
                      yStart: .value("Base", bar.base),
                      yEnd: .value("Total", bar.base + bar.extra),
                      width: .fixed(bar.width)
                  )
                  .foregroundStyle(bar.extraColor) // Красная/зеленая экстра
              }
          }
        .chartXAxis {
            AxisMarks(values: viewModel.axisConfig.values) { value in
                if let date = value.as(Date.self),
                   let bar = viewModel.bars.first(where: { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .hour) }),
                   let label = bar.timeLabel {
                    AxisValueLabel(label)
                } else {
                    AxisValueLabel(format: viewModel.axisConfig.labelFormat)
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: viewModel.yAxisStep)) { value in
                AxisGridLine()
                AxisValueLabel("\(Int(value.as(Double.self) ?? 0))")
            }
        }
        .chartXScale(domain: viewModel.axisConfig.domain)
        .chartYScale(domain: viewModel.yAxisRange)
        .frame(height: 300)
        .padding()
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedPeriod)
    }
}
