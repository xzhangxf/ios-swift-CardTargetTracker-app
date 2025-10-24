//
//  StorageManager.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import Foundation

class StorageManager {
    static let shared = StorageManager()
    private init(){
    }
    
    private let cardsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("cards.json")
    private let txURL    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("transactions.json")
    
    func loadCards() -> [Card]? {
        do {
            let data = try Data(contentsOf: cardsURL)
            let cards = try JSONDecoder().decode([Card].self, from: data)
            return cards
        } catch {
            print("Failed to load cards: \(error)")
            return nil
        }
    }
    
}
