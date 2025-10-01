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

struct SessionChartView: View {
    
    @State private var viewModel = SessionChartViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Period", selection: $viewModel.selectedPeriod) {
                ForEach(SessionChartViewModel.ChartPeriod.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            VStack {
                Text("Total sitting: \(Int(viewModel.totalSitting)) min")
                Text("Total exercising: \(Int(viewModel.totalExercising)) min")
            }
            .font(.headline)
            
            Chart {
                switch viewModel.selectedPeriod {
                case .day, .threeDays:
                    ForEach(viewModel.dailySessionsData) { session in
                        createSessionBar(session: session)
                    }
                    
                case .week, .month, .halfYear, .year:
                    ForEach(viewModel.selectedPeriod == .week ?
                                  viewModel.weeklySessionsData :
                                  viewModel.selectedPeriod == .month ?
                                  viewModel.monthlySessionsData :
                                  viewModel.selectedPeriod == .halfYear ?
                                  viewModel.halfYearSessionsData :
                                  viewModel.yearlySessionsData) { data in
                              createAggregatedBar(data: data)
                          }
                }
            }
            .chartXAxis {
                xAxis
            }
            .chartYAxis {
                yAxis
            }
//            .chartXScale(range: .plotDimension(padding: 10))
            .chartXScale(domain: viewModel.xAxisDomain, range: .plotDimension(padding: 5))

            .chartYScale(domain: 0...(viewModel.maxYValue * 1.1))
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
    
    private var xAxis: some AxisContent {
        AxisMarks(values: viewModel.xAxisValues) { value in
            AxisValueLabel(format: viewModel.xAxisLabelFormat)
            AxisTick()
            AxisGridLine()
        }
    }
    
    private var yAxis: some AxisContent {
          AxisMarks(values: .stride(by: viewModel.yAxisStep)) { value in
              AxisGridLine()
              AxisTick()
              AxisValueLabel {
                  if let doubleValue = value.as(Double.self) {
                      Text("\(Int(doubleValue))")
                  }
              }
          }
      }
    
    @ChartContentBuilder
    private func createSessionBar(session: SessionData) -> some ChartContent {
        createBar(
            xValue: session.sittingDate,
            base: session.sittingBase,
            extra: session.sittingOvertime,
            extraColor: viewModel.barColor(for: .sitting),
            width: viewModel.dynamicBarWidth
        )
        
        createBar(
            xValue: session.exercisingDate, 
            base: session.exercisingBase,
            extra: session.exercisingExtra,
            extraColor: viewModel.barColor(for: .exercising),
            width: viewModel.dynamicBarWidth
        )
    }

    @ChartContentBuilder
    private func createAggregatedBar(data: AggregatedData) -> some ChartContent {
        let adjustedDate = viewModel.calculateBarPosition(for: data)
        let extraColor = viewModel.barColor(for: data.activityType)
        
        createBar(
            xValue: adjustedDate,
            base: data.base,
            extra: data.extra,
            extraColor: extraColor,
            width: viewModel.dynamicBarWidth
        )
    }
    
    @ChartContentBuilder
    private func createBar(
        xValue: Date,
        base: Double,
        extra: Double,
        baseColor: Color = .gray,
        extraColor: Color,
        width: Double
    ) -> some ChartContent {
        
        // Base part
        BarMark(
            x: .value(viewModel.selectedPeriod == .day ? "Hours" : "Day", xValue),
            y: .value("Minutes", base),
            width: .fixed(width)
            
        )
        .foregroundStyle(baseColor.opacity(0.8))
        .clipShape(.rect(cornerRadius: .zero))
        
        // Extra part
        BarMark(
            x: .value(viewModel.selectedPeriod == .day ? "Hours" : "Day", xValue),
            yStart: .value("Base", base),
            yEnd: .value("Top", base + extra),
            width: .fixed(width)
        )
        .foregroundStyle(extraColor.opacity(0.8))
        .clipShape(.rect(cornerRadius: .zero))
    }
}


#Preview {
    SessionChartView()
}
