////
////  ChartView.swift
////  BarChart
////
////  Created by Denis Yaremenko on 29.09.2025.

import SwiftUI
import Charts
//
//  ChartView.swift
//

import SwiftUI
import Charts

struct SessionChartView: View {
    @State private var viewModel = SessionChartViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Period", selection: $viewModel.selectedPeriod) {
                Text("1 day").tag(SessionChartViewModel.ChartPeriod.day)
                Text("3 days").tag(SessionChartViewModel.ChartPeriod.threeDays)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Chart {
                ForEach(viewModel.chartBars) { bar in
                    BarMark(
                        x: .value("Period", bar.position),
                        y: .value("Minutes", bar.baseMinutes),
                        width: .fixed(bar.width)
                    )
                    .foregroundStyle(bar.baseColor)
                    
                    BarMark(
                        x: .value("Period", bar.position),
                        yStart: .value("Minutes", bar.baseMinutes),
                        yEnd: .value("Total Minutes", bar.baseMinutes + bar.extraMinutes),
                        width: .fixed(bar.width)
                    )
                    .foregroundStyle(bar.extraColor)
                }
            }
            .chartXAxis {
                AxisMarks(values: viewModel.xAxisCenters) { value in
                    if let date = value.as(Date.self),
                       let index = viewModel.xAxisCenters.firstIndex(of: date) {
                        AxisValueLabel(viewModel.xAxisLabels[index])
                    }
                    AxisTick()
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: viewModel.yAxisGridStep)) { value in
                    AxisGridLine()
                    AxisTick()
                    if let minutes = value.as(Double.self) {
                        AxisValueLabel("\(Int(minutes))")
                    }
                }
            }
            .chartXScale(domain: viewModel.xAxisRange)
            .chartYScale(domain: viewModel.yAxisRange)
            .chartPlotStyle { plot in
                plot
                    .background(Color.yellow.opacity(0.1))
                    .border(.black, width: 1)
            }
            .frame(height: 300)
            .padding()
        }
    }
}

#Preview {
    SessionChartView()
}
