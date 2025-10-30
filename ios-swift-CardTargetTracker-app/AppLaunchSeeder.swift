//
//  AppLaunchSeeder.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 30/10/25.
//

import Foundation

struct Preload {
    static func seedIfNeeded() {
        let key = "hasSeededDefaultCards_v1"
        let has = UserDefaults.standard.bool(forKey: key)
        guard !has else { return }

        let sample = makeSampleCards()
        // 假设 TransactionManager.shared.addCard(_:) 或 StorageManager 有相应 API
        for c in sample {
            TransactionManager.shared.addCard(c)
        }
        UserDefaults.standard.set(true, forKey: key)
    }

    static func makeSampleCards() -> [Card] {
        return [
            Card(id: UUID(), name: "DBS Everyday", targetCents: 500000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "OCBC 365", targetCents: 300000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "UOB PRVI", targetCents: 400000, cycle: .monthly(startDay: 1), notifyDaysBefore: 2, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "Citi Cash Back", targetCents: 200000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "Standard Chartered", targetCents: 350000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "POSB Everyday", targetCents: 250000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true)
        ]
    }
}
