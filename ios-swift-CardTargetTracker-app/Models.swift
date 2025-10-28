//
//  Models.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import Foundation

struct Card: Codable, Hashable, Identifiable{
    var id: UUID = UUID()
    var name: String
    var targetCents: Int
    var cycle: CycleType
    var notifyDaysBefore: Int
    var dailyReminderTime: DateComponents? // is a struct representing a date in terms of units (such as year, month, day, hour, and minute).
    var isActive: Bool = true
}

enum CycleType: Codable, Hashable {
    case monthly(startDay: Int)
//    case yearly(startYear: Int)
    case custom(days: Int, startDate: Date)
}

enum BillingCycle {
    /// Returns the current cycle window for the given card relative to `ref` date.
    static func window(for card: Card, ref: Date = Date(), calendar: Calendar = .current) -> DateInterval {
        switch card.cycle {
        case .monthly(let startDay):
            if startDay == 1 {
                // Calendar Month: 1st -> 1st (next month)
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: ref))!
                let startNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                return DateInterval(start: startOfMonth, end: startNextMonth)
            } else {
                // Statement cycle: start at day `startDay` of "current window"
                // If today is before this month's `startDay`, window started last month; else starts this month.
                let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: ref))!
                let thisMonthStartDay = calendar.date(bySetting: .day, value: min(startDay, maxDay(inMonthStarting: thisMonthStart, cal: calendar)), of: thisMonthStart)!

                let cycleStart: Date
                if ref < thisMonthStartDay {
                    // use previous month
                    let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
                    cycleStart = calendar.date(
                        bySetting: .day,
                        value: min(startDay, maxDay(inMonthStarting: prevMonthStart, cal: calendar)),
                        of: prevMonthStart
                    )!
                } else {
                    cycleStart = thisMonthStartDay
                }

                let nextMonthFromCycleStart = calendar.date(byAdding: .month, value: 1, to: cycleStart)!
                return DateInterval(start: cycleStart, end: nextMonthFromCycleStart)
            }
        case .custom(let days, let startDate):
            // Optional: If you use this case, treat as a rolling fixed-length window
            let start = mostRecentBoundary(from: startDate, stepDays: days, ref: ref, cal: calendar)
            let end = calendar.date(byAdding: .day, value: days, to: start)!
            return DateInterval(start: start, end: end)
        }
    }

    /// Inclusive day-count remaining until the window end (so 0 means "ends today").
    static func daysLeft(for card: Card, ref: Date = Date(), calendar: Calendar = .current) -> Int {
        let w = window(for: card, ref: ref, calendar: calendar)
        // days remaining = number of midnights from today to (end - 1 second)
        let startToday = calendar.startOfDay(for: ref)
        let lastActiveDay = calendar.date(byAdding: .day, value: -1, to: w.end)!
        let endDay = calendar.startOfDay(for: lastActiveDay)
        let comps = calendar.dateComponents([.day], from: startToday, to: endDay)
        return max(0, (comps.day ?? 0) + 1)
    }

    static func maxDay(inMonthStarting monthStart: Date, cal: Calendar) -> Int {
        cal.range(of: .day, in: .month, for: monthStart)?.count ?? 28
    }
    static func mostRecentBoundary(from start: Date, stepDays: Int, ref: Date, cal: Calendar) -> Date {
        guard stepDays > 0 else { return start }
        var s = start
        while let next = cal.date(byAdding: .day, value: stepDays, to: s), next <= ref { s = next }
        return s
    }
}


enum Category: String, Codable, CaseIterable{
    case diningAndFoodDelivery
    case groceriesAndSupermarkets
    case onlineShopping
    case transportAndRIdeHailing
    case utiltiesAndPhoneBills
    case entertaimentAndStreaming
    case publicTransport
    case retailAndDepartmentStores
    case pharmacyAndWellness
    case insuranceAndEducationFees
    case foreignCurrencyOrOverseasSpend
    case HotelsAndFlights
}

struct Transaction: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var cardId: UUID
    var amountCents: Int                      // store cents to avoid float issues
    var category: Category
    var date: Date
    var note: String?
}

struct SettingsMode: Codable {
    var isNotificationEnabled: Bool
    var defaultNotifyDaysBefore: Int
    var defaultDailyReminderTime: DateComponents?
}

