//
//  TestData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 30.09.2025.
//

import Foundation

enum SampleData {
    static let sessions: [M_Session] = [
        M_Session(
            sittingStartedAt: createDate(dayOffset: 0, hour: 11),
            sittingOverall: 20,
            sittingOvertime: 10,
            exercisingStartedAt: createDate(dayOffset: 0, hour: 11, minute: 30),
            exercisingOverall: 10,
            exercisingOvertime: 10
        )
    ]
    
    static func createDate(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
    }
}
