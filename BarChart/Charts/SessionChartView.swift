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

//
//  SessionChartView.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.10.2025.
//

import SwiftUI
import Charts

//
//  SessionChartView.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.10.2025.
//

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
            ForEach(SessionChartViewModel.ChartPeriod.allCases, id: \.self) {
                Text($0.displayName).tag($0)
            }
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
                    x: .value("Time", bar.xValue),
                    y: .value("Minutes", bar.baseHeight),
                    width: .fixed(bar.width)
                )
                .foregroundStyle(bar.baseColor)
                .clipShape(.rect(cornerRadius: .zero))

                BarMark(
                    x: .value("Time", bar.xValue),
                    yStart: .value("Base", bar.baseHeight),
                    yEnd: .value("Top", bar.baseHeight + bar.extraHeight),
                    width: .fixed(bar.width)
                )
                .foregroundStyle(bar.extraColor)
                .clipShape(.rect(cornerRadius: .zero))
            }
        }
        .chartXAxis {
            AxisMarks(values: viewModel.xAxisValues) { value in
                if viewModel.selectedPeriod == .day,
                   let date = value.as(Date.self),
                   let bar = viewModel.chartBars.first(where: {
                       Calendar.current.isDate($0.xValue, inSameDayAs: date) &&
                       Calendar.current.component(.hour, from: $0.xValue) == Calendar.current.component(.hour, from: date)
                   }),
                   let intervalLabel = bar.intervalLabel {
                    AxisValueLabel(intervalLabel)
                } else {
                    AxisValueLabel(format: viewModel.xAxisLabelFormat)
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
        .chartXScale(domain: viewModel.xAxisDomain, range: .plotDimension(padding: 5))
        .chartYScale(domain: viewModel.chartYScaleDomain)
        .chartPlotStyle { plotContent in
            plotContent
                .background(Color.yellow.opacity(0.1))
                .border(.black, width: 1)
        }
        .frame(height: 300)
        .padding()
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedPeriod)
    }
}

#Preview {
    SessionChartView()
}
