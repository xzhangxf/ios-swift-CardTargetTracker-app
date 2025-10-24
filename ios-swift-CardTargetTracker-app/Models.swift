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
    case yearly(startYear: Int)
    case custom(days: Int, startDate: Date)
}

enum Category: String, Codable, CaseIterable{
    case diningAndFoodDelivery
    case groceriesAndSupermarkets
    case onlineShopping
    case transoirtAndRIdeHailing
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

