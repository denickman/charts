//
//  TestData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 30.09.2025.
//

import Foundation

func createDate(dayOffset: Int, hour: Int) -> Date {
    let calendar = Calendar.current
    let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
    return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
}




let testSessionsData: [SessionData] = [
    
    .init(
        sittingDate: createDate(dayOffset: -30, hour: 10),
        exercisingDate: createDate(dayOffset: -30, hour: 11),
        sittingBase: 30,
        sittingOvertime: 10,
        exercisingBase: 15,
        exercisingExtra: 5
    ),
    
    .init(
        sittingDate: createDate(dayOffset: -60, hour: 11),
        exercisingDate: createDate(dayOffset: -60, hour: 12),
        sittingBase: 25,
        sittingOvertime: 5,
        exercisingBase: 20,
        exercisingExtra: 5
    ),
    .init(
        sittingDate: createDate(dayOffset: -90, hour: 13),
        exercisingDate: createDate(dayOffset: -90, hour: 14),
        sittingBase: 35,
        sittingOvertime: 15,
        exercisingBase: 15,
        exercisingExtra: 10
    ),
    
    
    .init(
        sittingDate: createDate(dayOffset: -5, hour: 10),
        exercisingDate: createDate(dayOffset: -5, hour: 11),
        sittingBase: 10,
        sittingOvertime: 5,
        exercisingBase: 5,
        exercisingExtra: 5
    ),
        .init(
            sittingDate: createDate(dayOffset: -5, hour: 12),
            exercisingDate: createDate(dayOffset: -5, hour: 13),
            sittingBase: 30,
            sittingOvertime: 15,
            exercisingBase: 15,
            exercisingExtra: 5
        ),

        .init(
            sittingDate: createDate(dayOffset: -2, hour: 1),
            exercisingDate: createDate(dayOffset: -2, hour: 2),
            sittingBase: 30,
            sittingOvertime: 15,
            exercisingBase: 15,
            exercisingExtra: 5
        ),
    .init(
        sittingDate: createDate(dayOffset: -2, hour: 3),
        exercisingDate: createDate(dayOffset: -2, hour: 4),
        sittingBase: 30,
        sittingOvertime: 15,
        exercisingBase: 5,
        exercisingExtra: 5
    ),
    
        .init(
            sittingDate: createDate(dayOffset: -2, hour: 7),
            exercisingDate: createDate(dayOffset: -2, hour: 8),
            sittingBase: 10,
            sittingOvertime: 15,
            exercisingBase: 10,
            exercisingExtra: 5
        ),
    
        .init(
            sittingDate: createDate(dayOffset: -2, hour: 17),
            exercisingDate: createDate(dayOffset: -2, hour: 18),
            sittingBase: 20,
            sittingOvertime: 25,
            exercisingBase: 20,
            exercisingExtra: 5
        ),
    
    
    

        .init(
            sittingDate: createDate(dayOffset: -1, hour: 7),
            exercisingDate: createDate(dayOffset: -1, hour: 8),
            sittingBase: 40,
            sittingOvertime: 10,
            exercisingBase: 15,
            exercisingExtra: 5
        ),
    .init(
        sittingDate: createDate(dayOffset: -1, hour: 9),
        exercisingDate: createDate(dayOffset: -1, hour: 10),
        sittingBase: 30,
        sittingOvertime: 5,
        exercisingBase: 15,
        exercisingExtra: 5
    ),

        .init(
            sittingDate: createDate(dayOffset: 0, hour: 6),
            exercisingDate: createDate(dayOffset: 0, hour: 7),
            sittingBase: 45,
            sittingOvertime: 15,
            exercisingBase: 15,
            exercisingExtra: 5
        ),
    .init(
        sittingDate: createDate(dayOffset: 0, hour: 8),
        exercisingDate: createDate(dayOffset: 0, hour: 9),
        sittingBase: 30,
        sittingOvertime: 5,
        exercisingBase: 15,
        exercisingExtra: 5
    ),
]
