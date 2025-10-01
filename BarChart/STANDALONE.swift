//
//  STANDALONE.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

//
//  ChartView.swift
//  BarChart
//
//  Created by Denis Yaremenko on 29.09.2025.
//

import Foundation
import SwiftUI
import Charts


struct SessionChartData2: Identifiable {
    let id = UUID()

    let sittingDate: Date
    let exercisingDate: Date

    let sittingBase: Double
    let sittingOvertime: Double

    let exercisingBase: Double
    let exercisingExtra: Double
}


struct SessionChartView2: View {

    let sessionsData: [SessionChartData2] = [
        // Первая сессия
        .init(
            sittingDate: Date().addingTimeInterval(-3 * 3600),   // 2 часа назад
            exercisingDate: Date().addingTimeInterval(-2 * 3600), // после окончания сидячей сессии
            sittingBase: 50,
            sittingOvertime: 10,
            exercisingBase: 15,
            exercisingExtra: 5
        ),

        // Вторая сессия
        .init(
            sittingDate: Date().addingTimeInterval(-1 * 3600),   // 1 час назад
            exercisingDate: Date().addingTimeInterval(-0.5 * 3600), // после окончания сидячей сессии
            sittingBase: 35,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 5
        )
    ]

    var body: some View {
        VStack {
            Text("Total sitting: \(sessionsData.reduce(0) { $0 + ($1.sittingBase + $1.sittingOvertime) })")
            Text("Total exercising: \(sessionsData.reduce(0) { $0 + ($1.exercisingBase + $1.exercisingExtra) })")

            Chart {
                ForEach(sessionsData) { session in
                    createBar(
                        for: session.sittingDate,
                        type: "Sitting",
                        base: session.sittingBase,
                        extra: session.sittingOvertime,
                        baseColor: .gray,
                        extraColor: .red
                    )

                    createBar(
                        for: session.exercisingDate,
                        type: "Exercising",
                        base: session.exercisingBase,
                        extra: session.exercisingExtra,
                        baseColor: .gray,
                        extraColor: .green
                    )
                }

                RuleMark(y: .value("Goal", 75))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [10]))
                    .annotation(alignment: .leading) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
            }
            .chartXAxis {
                AxisMarks(values: fixedXAxisMarks()) { value in

//                    AxisValueLabel(format: .dateTime.month(.narrow), centered: false)
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)), centered: true)
                    AxisTick()
                    AxisGridLine()
                }
            }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                        AxisTick()
                        AxisGridLine()
                            .foregroundStyle(.blue)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 300)
        .chartYScale(domain: 0...100) // max y value
//        .chartXAxis(.hidden)
//        .chartYAxis(.hidden)
        .chartPlotStyle(content: { plotContent in
            plotContent
                .background(Color.yellow.opacity(0.1))
                .border(.green, width: 2)
        })
        .padding()
    }

    func fixedXAxisMarks() -> [Date] {
        var marks: [Date] = []
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)

        let hours = [0, 6, 12, 18]
        for hour in hours {
            if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: calendar.date(from: components)!) {
                marks.append(date)
            }
        }

        return marks
    }


    @ChartContentBuilder
    func createBar(for date: Date, type: String, base: Double, extra: Double, baseColor: Color, extraColor: Color) -> some ChartContent {
        // Base часть
        BarMark(
            x: .value("Time", date),
            y: .value("Minutes", base)
        )
        .position(by: .value("Type", type))
        .foregroundStyle(baseColor.gradient)
//        .cornerRadius(50)

        // Extra часть сверху
        BarMark(
            x: .value("Time", date),
            yStart: .value("Base", base),
            yEnd: .value("Top", base + extra)
        )
        .position(by: .value("Type", type))
        .foregroundStyle(extraColor.gradient)
//        .cornerRadius(50)
    }


}


#Preview {
    SessionChartView2()
}



