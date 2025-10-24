//
//  PeriodCalculator.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import Foundation

enum PeriodPreset {case thisWeek, thisMonth, all}

struct PeriodCalculator {
    static func window(preset: PeriodPreset, calendar: Calendar = .current) -> DateInterval? {
        let now = Date()
        switch preset{
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return DateInterval(start: start, end: min(end, now))
        case .thisMonth:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: min(end, now))
        case .all:
            return nil
        }
    }
}
