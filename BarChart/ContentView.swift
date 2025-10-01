//
//  ContentView.swift
//  BarChart
//
//  Created by Sean Allen on 11/28/22.
//

import SwiftUI
import Charts

// The commented out code is me showing various syting options for the chart
// I showcase each option in the video if you're interested.
struct ContentView: View {

    let viewMonths: [ViewMonth] = [
        .init(date: Date.from(year: 2023, month: 1, day: 1), viewCount: 55000),
        .init(date: Date.from(year: 2023, month: 2, day: 1), viewCount: 89000),
        .init(date: Date.from(year: 2023, month: 3, day: 1), viewCount: 64000),
        .init(date: Date.from(year: 2023, month: 4, day: 1), viewCount: 79000),
        .init(date: Date.from(year: 2023, month: 5, day: 1), viewCount: 130000),
        .init(date: Date.from(year: 2023, month: 6, day: 1), viewCount: 90000),
        .init(date: Date.from(year: 2023, month: 7, day: 1), viewCount: 88000),
        .init(date: Date.from(year: 2023, month: 8, day: 1), viewCount: 64000),
        .init(date: Date.from(year: 2023, month: 9, day: 1), viewCount: 74000),
        .init(date: Date.from(year: 2023, month: 10, day: 1), viewCount: 99000),
        .init(date: Date.from(year: 2023, month: 11, day: 1), viewCount: 110000),
        .init(date: Date.from(year: 2023, month: 12, day: 1), viewCount: 94000)
    ]

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("YouTube Views")
                    .bold()
//                    .padding(.top)

                Text("Total: \(viewMonths.reduce(0, { $0 + $1.viewCount }))")
                    .fontWeight(.semibold)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                Chart {

                    ForEach(viewMonths) { viewMonth in
                    // BarMark Line Point Area Rule Rectangle
                        BarMark(
                            x: .value("Month", viewMonth.date, unit: .month),
                            y: .value("Views", viewMonth.viewCount)
                        )
                        .foregroundStyle(Color.pink.gradient)
                    }
                    
                    RuleMark(y: .value("Goal", 80000))
                        .foregroundStyle(.mint)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [10]))
                       // .annotation(position: .leading, alignment: .leading) {
                        .annotation(alignment: .leading) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                }
                .frame(height: 180)
//                .chartXAxis(.hidden)
//                .chartYAxis(.hidden)
                
                .chartXAxis {
                    AxisMarks(values: viewMonths.map { $0.date }) { date in
                        AxisGridLine()
//                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                    }
                }
//                .chartYAxis { // смена позиции лейлблов горизонатльно
//                    AxisMarks(position: .leading)
//                }
//                .chartYAxis {
//                    AxisMarks { mark in
//                        AxisValueLabel()
//                        AxisGridLine()
//                    }
//                }
                .padding(.bottom)
                .chartYScale(domain: 0...200000) // обрезает график в пределах min...max values
                
//                .chartPlotStyle { plotContent in // дает тебе бекграунд
//                    plotContent
//                        .background(.teal.gradient.opacity(0.2))
//                        .border(.green, width: 3)
//                }

                HStack {
                    Image(systemName: "line.diagonal")
                        .rotationEffect(Angle(degrees: 45))
                        .foregroundStyle(.mint)

                    Text("Monthly Goal")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
                .padding(.leading, 4)

                Spacer()
            }

            Text("D")
                .foregroundStyle(.secondary)
                .font(.caption2)
                .fontWeight(.medium)
                .offset(x: 108, y: -121)
        }
        .padding(30)
    }
}

#Preview {
    ContentView()
}
