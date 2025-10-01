//
//  ViewMonth.swift
//  BarChart
//
//  Created by Denis Yaremenko on 26.05.2025.
//

import Foundation

struct ViewMonth: Identifiable {
    let id = UUID()
    let date: Date
    let viewCount: Int
}

extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components)!
    }
}
