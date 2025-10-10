////
////  ChartView.swift
////  BarChart
////
////  Created by Denis Yaremenko on 29.09.2025.

import SwiftUI
import Charts

struct SessionChartView: View {
    @State private var viewModel = SessionChartViewModel()

    var body: some View {
        VStack(spacing: 16) {
            periodPicker
            chartView
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            Text("1 day").tag(SessionChartViewModel.ChartPeriod.day)
            Text("3 days").tag(SessionChartViewModel.ChartPeriod.threeDays)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var chartView: some View {
        Chart {
            ForEach(viewModel.chartBars) { bar in
                BarMark(
                    x: .value("Period", bar.mappedPositionDate),
                    y: .value("Min", bar.baseMinutes),
                    width: .fixed(bar.width)
                )
                .foregroundStyle(bar.baseColor)
                
                BarMark(
                    x: .value("Period", bar.mappedPositionDate),
                    yStart: .value("Min", bar.baseMinutes),
                    yEnd: .value("Total", bar.baseMinutes + bar.extraMinutes),
                    width: .fixed(bar.width)
                )
                .foregroundStyle(bar.extraColor)
            }
        }
        .chartXAxis {
            AxisMarks(values: viewModel.axisMarkCenters) { value in
                if let date = value.as(Date.self),
                   let index = viewModel.axisMarkCenters.firstIndex(of: date) {
                    AxisValueLabel {
                        Text(viewModel.axisLabels[index])
                    }
                }
                AxisTick()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: viewModel.yAxisGridStep)) { value in
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
        .chartYScale(domain: viewModel.yAxisDomain)
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
