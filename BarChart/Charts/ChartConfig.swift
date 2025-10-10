//
//  ChartConfig.swift
//  BarChart
//
//  Created by Denis Yaremenko on 07.10.2025.
//

import Foundation
import SwiftUI

import Foundation
import SwiftUI

enum ChartConfig {
    enum Bar {
        static let defaultWidth: Double = 14.0
        static let minWidth: Double = 4.0
    }
    
    enum Time {
        static let secondsInHour: TimeInterval = 3600
        static let hoursInDay: Double = 24.0
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
        static let dayCenterHour: Int = 12
    }
    
    enum DataRanges {
        static let binHours: Int = 2  // Для 2-часовых бинов в дне
    }
    
    enum Colors {
        static let sittingBase = Color.gray.opacity(0.8)
        static let sittingExtra = Color.red.opacity(0.8)
        static let exercisingBase = Color.gray.opacity(0.8)
        static let exercisingExtra = Color.green.opacity(0.8)
    }
}
