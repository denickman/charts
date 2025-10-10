//
//  ChartConfig.swift
//  BarChart
//
//  Created by Denis Yaremenko on 07.10.2025.
//

import Foundation
import SwiftUI

enum ChartConfig {
    static let secondsInHour: TimeInterval = 3600
    static let hoursInDay: Double = 24.0
    static let threeDaysOffset: Int = -2
    static let dayCenterHour: Int = 12
    static let segmentHours: Int = 2
    
    enum Bar {
        static let minWidth: Double = 4.0
    }
    
    enum Axis {
        static let defaultPeriodInMinutes: Double = 60.0
        
        enum YAxis {
            static let maxScaleFactor: Double = 1.1
            static let mediumThreshold: Double = 2
            static let largeThreshold: Double = 4
            static let stepDivisor: Double = 4
        }
        
        enum GridStep: Double {
            case small = 10, medium = 15, large = 30
        }
    }
    
    enum Colors {
        static let sittingBase = Color.gray.opacity(0.8)
        static let sittingExtra = Color.red.opacity(0.8)
        static let exercisingBase = Color.gray.opacity(0.8)
        static let exercisingExtra = Color.green.opacity(0.8)
    }
    
    static func barWidth(for barCount: Int) -> Double {
        switch barCount {
        case ...2: return 30.0
        case 3...4: return 28.0
        case 5...6: return 26.0
        case 7...8: return 24.0
        case 9...14: return 20.0
        default: return Bar.minWidth
        }
    }
}
