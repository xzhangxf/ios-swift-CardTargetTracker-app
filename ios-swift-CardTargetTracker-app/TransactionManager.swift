//
//  TransactionManager.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import Foundation

class TransactionManager {
    static let shared = TransactionManager()
    
    private init() {
        cards = StorageManager.shared.loadCards() ?? []
        transactions = StorageManager.shared.loadTransactions()
    }

    private var cards: [Card]
    private var transactions: [Transaction]
    
    func allCards() -> [Card] {
        cards
    }
    
    func allTransactions() -> [Transaction] {
        transactions
    }
    
    func addCard(_ card: Card) {
        cards.append(card); persist()
    }
    
    func transactions(forCard id: UUID) -> [Transaction] {
        transactions.filter { $0.cardId == id }
    }
    
    func updateCard(_ card: Card) {
        if let i = cards.firstIndex(where: { $0.id == card.id }) { cards[i] = card; persist() }
    }
    
    func deleteCard(id: UUID) {
        cards.removeAll { $0.id == id }
        transactions.removeAll { $0.cardId == id }
        persist()
    }
    
    func getCard(id: UUID) -> Card? {
        return cards.first(where: { $0.id == id })
    }
    
    func getCards() -> [Card] {
        return cards
    }
    
    func addTransaction(_ t: Transaction) {
        transactions.append(t); persist()
    }
    
    func updateTransaction(_ t: Transaction) {
        if let i = transactions.firstIndex(where: { $0.id == t.id }) { transactions[i] = t; persist() }
    }
    
    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }; persist()
    }

    func persist() {
        StorageManager.shared.saveCards(cards)
        StorageManager.shared.saveTransactions(transactions)
    }

    //filters
    func transactions(in window: DateInterval?) -> [Transaction] {
        guard let w = window else { return transactions }
        return transactions.filter { w.contains($0.date) }
    }

    // Daily grouping
    func groupByDay(in window: DateInterval?, calendar: Calendar = .current) -> [(day: Date, items: [Transaction], totalCents: Int)] {
        let tx = transactions(in: window)
        let grouped = Dictionary(grouping: tx) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { (key: $0.key, value: $0.value) }
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, items: $0.value, totalCents: $0.value.reduce(0) { $0 + $1.amountCents }) }
    }

    // Category aggregation
    func totalsByCategory(in window: DateInterval?) -> [(category: Category, cents: Int)] {
        let tx = transactions(in: window)
        let grouped = Dictionary(grouping: tx) { $0.category }
        return grouped.map { (category: $0.key, cents: $0.value.reduce(0) { $0 + $1.amountCents }) }
                      .sorted { $0.cents > $1.cents }
    }

    // Per card spent in window
    func spentForCard(_ cardId: UUID, in window: DateInterval?) -> Int {
        transactions(in: window).filter { $0.cardId == cardId }.reduce(0) { $0 + $1.amountCents }
    }
}
