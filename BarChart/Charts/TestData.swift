//
//  TestData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 30.09.2025.
//

import Foundation

func createDate(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
    let calendar = Calendar.current
    let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
}

let testSessionsData: [M_Session] = [
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 8, minute: 30)
    ),
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 9, minute: 30)
    ),
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 13)
    ),
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 15)
    )
]
