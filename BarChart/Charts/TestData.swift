//
//  TestData.swift
//  BarChart
//
//  Created by Denis Yaremenko on 30.09.2025.
//

import Foundation

enum SampleData {
    static let sessions: [Session] = [
        Session(
            date: createDate(dayOffset: 0, hour: 8),
            sitting: Activity(base: 20, extra: 10),
            exercising: Activity(base: 10, extra: 5)
        )
    ]
    
    static func createDate(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
    }
}

