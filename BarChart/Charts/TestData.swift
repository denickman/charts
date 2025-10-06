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

// year / half
let testSessionsData: [SessionData] = [

    .init(
        sittingDate: createDate(dayOffset: -120, hour: 10),
        exercisingDate: createDate(dayOffset: -120, hour: 11),
        sittingBase: 30,
        sittingOvertime: 10,
        exercisingBase: 10,
        exercisingExtra: 10
    ),
    
        .init(
            sittingDate: createDate(dayOffset: -90, hour: 10),
            exercisingDate: createDate(dayOffset: -90, hour: 11),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    .init(
        sittingDate: createDate(dayOffset: -60, hour: 11),
        exercisingDate: createDate(dayOffset: -60, hour: 12),
        sittingBase: 30,
        sittingOvertime: 10,
        exercisingBase: 10,
        exercisingExtra: 10
    ),
    .init(
        sittingDate: createDate(dayOffset: -30, hour: 13),
        exercisingDate: createDate(dayOffset: -30, hour: 14),
        sittingBase: 30,
        sittingOvertime: 10,
        exercisingBase: 10,
        exercisingExtra: 10
    ),
    
        .init(
            sittingDate: createDate(dayOffset: -28, hour: 10),
            exercisingDate: createDate(dayOffset: -28, hour: 11),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: -21, hour: 10),
            exercisingDate: createDate(dayOffset: -21, hour: 11),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: -14, hour: 10),
            exercisingDate: createDate(dayOffset: -14, hour: 11),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: -7, hour: 12),
            exercisingDate: createDate(dayOffset: -7, hour: 13),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: 0, hour: 14),
            exercisingDate: createDate(dayOffset: 0, hour: 15),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: 0, hour: 16),
            exercisingDate: createDate(dayOffset: 0, hour: 17),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: 0, hour: 18),
            exercisingDate: createDate(dayOffset: 0, hour: 19),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: 0, hour: 20),
            exercisingDate: createDate(dayOffset: 0, hour: 21),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
        .init(
            sittingDate: createDate(dayOffset: 0, hour: 22),
            exercisingDate: createDate(dayOffset: 0, hour: 23),
            sittingBase: 30,
            sittingOvertime: 10,
            exercisingBase: 10,
            exercisingExtra: 10
        ),
    
]

