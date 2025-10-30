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
            // DBS / POSB
            Card(id: UUID(), name: "DBS Live Fresh", targetCents: 60000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "DBS Woman’s World", targetCents: 200000, cycle: .monthly(startDay: 1), notifyDaysBefore: 5, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "DBS Altitude Visa", targetCents: 300000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "POSB Everyday Card", targetCents: 80000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true),
            
            // OCBC
            Card(id: UUID(), name: "OCBC 365", targetCents: 80000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "OCBC Titanium Rewards", targetCents: 100000, cycle: .monthly(startDay: 1), notifyDaysBefore: 2, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "OCBC FRANK", targetCents: 40000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true),
            
            // UOB
            Card(id: UUID(), name: "UOB One", targetCents: 50000, cycle: .monthly(startDay: 1), notifyDaysBefore: 5, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "UOB EVOL", targetCents: 60000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "UOB PRVI Miles", targetCents: 100000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            
            // Citi
            Card(id: UUID(), name: "Citi Cash Back", targetCents: 80000, cycle: .monthly(startDay: 1), notifyDaysBefore: 2, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "Citi Rewards", targetCents: 100000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "Citi PremierMiles", targetCents: 200000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            
            // Standard Chartered
            Card(id: UUID(), name: "SCB Simply Cash", targetCents: 50000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "SCB Smart Credit Card", targetCents: 60000, cycle: .monthly(startDay: 1), notifyDaysBefore: 0, dailyReminderTime: nil, isActive: true),
            
            // Maybank
            Card(id: UUID(), name: "Maybank Family & Friends", targetCents: 80000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "Maybank Horizon Visa", targetCents: 100000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            
            // HSBC / AMEX
            Card(id: UUID(), name: "HSBC Revolution", targetCents: 80000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true),
            Card(id: UUID(), name: "AMEX True Cashback", targetCents: 50000, cycle: .monthly(startDay: 1), notifyDaysBefore: 3, dailyReminderTime: nil, isActive: true)
        ]
    }
}
