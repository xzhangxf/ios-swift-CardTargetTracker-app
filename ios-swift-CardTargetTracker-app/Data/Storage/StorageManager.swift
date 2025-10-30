//
//  StorageManager.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import Foundation

class StorageManager {
    static let shared = StorageManager()
    private init(){}
    //File System (FileManager): For storing larger files or custom data formats, you can directly interact with the app's sandboxed directories, such as the Documents directory for user-generated content or the Caches directory for temporary data.
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
    
    //    func loadCards() -> [Card] {
    //        (try? Data(contentsOf: cardsURL)).flatMap { try? JSONDecoder().decode([Card].self, from: $0) } ?? []
    //    }
    
    func saveCards(_ cards: [Card]) {
        do {
            let data = try JSONEncoder().encode(cards)
            try data.write(to: cardsURL, options: .atomic)
        } catch {
            print("saveCards error:", error)
        }
    }
    
    //    func loadTransactions() -> [Transaction] {
    //        (try? Data(contentsOf: txURL)).flatMap { try? JSONDecoder().decode([Transaction].self, from: $0) } ?? []
    //    }
    
    func loadTransactions() -> [Transaction] {
        do {
            let data = try Data(contentsOf: txURL)
            let txs = try JSONDecoder().decode([Transaction].self, from: data)
            return txs
        }catch{
            print("loadCards error:", error)
        }
        return []
    }
    
    func saveTransactions(_ txs: [Transaction]) {
        do {
            let data = try JSONEncoder().encode(txs)
            try data.write(to: txURL, options: .atomic)
        } catch {
            print("saveTransactions error:", error)
        }
    }
}
