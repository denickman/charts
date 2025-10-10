//
//  ChartConfig.swift
//  BarChart
//
//  Created by Denis Yaremenko on 07.10.2025.
//

import Foundation
import SwiftUI

enum ChartConfig {
    enum Bar {
        static let defaultWidth: CGFloat = 14.0
        static let minWidth: CGFloat = 4.0
        static let maxWidth: CGFloat = 16.0
        
        enum WidthAdjustments {
            static let lowDataThreshold: Int = 8
            static let mediumDataThreshold: Int = 16
            static let yearWidthMultiplier: Double = 1.2
        }
    }
    
    enum Time {
        static let secondsInHour: TimeInterval = 3600
        static let minutesInHour: Double = 60.0
        static let hoursInDay: Double = 24.0
        static let daysInWeek: Double = 7.0
        static let monthsInHalfYear: Int = 6
        static let monthsInYear: Int = 12
    }
    
    enum Axis {
        static let defaultPeriodInMinutes: Double = 60.0
        
        enum YAxis {
            static let maxMultiplier: Double = 1.1
            static let denseGridStep: Double = 10
            static let normalGridStep: Double = 15
            static let sparseGridStep: Double = 30
            static let normalGridThreshold: Double = 2
            static let sparseGridThreshold: Double = 4
            static let autoCalculationDivisor: Double = 4
        }
    }
    
    enum DateOffsets {
        static let threeDays: Int = -2
        static let week: Int = -6
        static let halfOfMonth: Int = -14
        static let month: Int = -29
        static let halfYearMonth: Int = -5
        static let dayCenterHour: Int = 12
        static let yearCenterDays: Int = 15
        static let yearTimeOffsetDays: Double = 7.5
    }
    
    enum TimeOffsets {
        static let weekHours: Double = 4
        static let monthHours: Double = 6
        static let halfYearDays: Int = 1
    }
    
    enum DataRanges {
        static let dayHours: [Int] = [0, 6, 12, 18]
        static let threeDaysRange: ClosedRange<Int> = -2...0
        static let weekRange: ClosedRange<Int> = -6...0
        static let monthWeeks: Int = 5
        static let weekDaysInterval: Int = 7
    }
    
    enum Colors {
        static let sittingBase = Color.gray.opacity(0.8)
        static let sittingExtra = Color.red.opacity(0.8)
        static let exercisingBase = Color.gray.opacity(0.8)
        static let exercisingExtra = Color.green.opacity(0.8)
    }
    
    
}
