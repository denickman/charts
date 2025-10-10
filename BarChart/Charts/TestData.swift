//
//  TestData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 30.09.2025.
//

import Foundation

import Foundation

func createDate(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
    let calendar = Calendar.current
    let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
}

let testSessionsData: [M_Session] = [
//    // День -2 (для 3 дней)
//    .init(
//        sittingOverall: 30,
//        sittingOvertime: 10,
//        exercisingOverall: 10,
//        exercisingOvertime: 10,
//        createdAt: createDate(dayOffset: -2, hour: 10)
//    ),
//    // День -1
//    .init(
//        sittingOverall: 30,
//        sittingOvertime: 30,
//        exercisingOverall: 10,
//        exercisingOvertime: 10,
//        createdAt: createDate(dayOffset: -1, hour: 12)
//    ),
//    .init(
//        sittingOverall: 30,
//        sittingOvertime: 30,
//        exercisingOverall: 10,
//        exercisingOvertime: 10,
//        createdAt: createDate(dayOffset: -1, hour: 14)  // Тот же бин 14-16? Нет, 14 -> bin 14-16
//    ),
//    .init(
//        sittingOverall: 30,
//        sittingOvertime: 30,
//        exercisingOverall: 10,
//        exercisingOvertime: 10,
//        createdAt: createDate(dayOffset: -1, hour: 16)
//    ),
    // День 0 (сегодня)
    
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 8, minute: 30)  // Bin 8-10 (9 -> 8)
    ),
    
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 9, minute: 30)  // Bin 8-10 (9 -> 8)
    ),
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 13)  // Bin 10-12
    ),
    // Добавим несколько в один бин для суммирования
    .init(
        sittingOverall: 20,
        sittingOvertime: 10,
        exercisingOverall: 5,
        exercisingOvertime: 5,
        createdAt: createDate(dayOffset: 0, hour: 14)  // Тот же bin 10-12
    )
]
