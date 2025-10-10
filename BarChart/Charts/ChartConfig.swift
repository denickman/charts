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
        static let minWidth: Double = 4.0
    }
    
    static func barWidth(for numberOfBars: Int) -> Double {
        if numberOfBars <= 2 {
            return 30.0
        } else if numberOfBars <= 4 {
            return 28.0
        } else if numberOfBars <= 6 {
            return 26.0
        } else if numberOfBars <= 8 {
            return 24.0
        } else if numberOfBars <= 14 {
            return 20.0
        } else {
            return Bar.minWidth
        }
    }
    
    static let secondsInHour: TimeInterval = 3600
    static let hoursInDay: Double = 24.0
    
    enum Axis {
        static let defaultPeriodInMinutes: Double = 60.0
        
        enum YAxis {
            static let yAxisMaxScaleFactor: Double = 1.1
            static let mediumGridThresholdHours: Double = 2
            static let largeGridThresholdHours: Double = 4
            static let yAxisStepDivisor: Double = 4
        }
        
        enum GridStep: Double {
            case small = 10
            case medium = 15
            case large = 30
        }
    }
    
    static let threeDaysOffset: Int = -2
    static let dayCenterHour: Int = 12
    static let segmentHours: Int = 2
    
    enum Colors {
        static let sittingBase = Color.gray.opacity(0.8)
        static let sittingExtra = Color.red.opacity(0.8)
        static let exercisingBase = Color.gray.opacity(0.8)
        static let exercisingExtra = Color.green.opacity(0.8)
    }
}
