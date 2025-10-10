////
////  ChartView.swift
////  BarChart
////
////  Created by Denis Yaremenko on 29.09.2025.
////
//
import Foundation
import SwiftUI
import Charts
import SwiftUI
import Charts

struct SessionChartView: View {
    @State private var viewModel = SessionChartViewModel()

    var body: some View {
        VStack(spacing: 16) {
            periodPicker
            totalsView
            chartView
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            Text("1 Day").tag(SessionChartViewModel.ChartPeriod.day)
            Text("3 Days").tag(SessionChartViewModel.ChartPeriod.threeDays)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var totalsView: some View {
        VStack {
            Text("Total sitting: \(Int(viewModel.totalSitting)) min")
            Text("Total exercising: \(Int(viewModel.totalExercising)) min")
        }
        .font(.headline)
    }

    private var chartView: some View {
        Chart {
            ForEach(viewModel.chartBars) { bar in
                BarMark(
                    x: .value("Period", bar.xValue),
                    y: .value("Minutes", bar.baseHeight),
                    width: .fixed(bar.width)
                )
                .foregroundStyle(bar.baseColor)
                
                BarMark(
                    x: .value("Period", bar.xValue),
                    yStart: .value("Base", bar.baseHeight),
                    yEnd: .value("Top", bar.baseHeight + bar.extraHeight),
                    width: .fixed(bar.width)
                )
                .foregroundStyle(bar.extraColor)
            }
        }
        .chartXAxis {
            AxisMarks(values: viewModel.periodCenters) { value in
                if let date = value.as(Date.self),
                   let index = viewModel.periodCenters.firstIndex(of: date) {
                    AxisValueLabel {
                        Text(viewModel.periodLabels[index])
                    }
                }
                AxisTick()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: viewModel.yAxisGridLineInterval)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
                    }
                }
            }
        }
        .chartXScale(domain: viewModel.xAxisDomain)
        .chartYScale(domain: viewModel.chartYScaleDomain)
        .chartPlotStyle { plotContent in
            plotContent
                .background(Color.yellow.opacity(0.1))
                .border(.black, width: 1)
        }
        .frame(height: 300)
        .padding()
    }
}

#Preview {
    SessionChartView()
}
