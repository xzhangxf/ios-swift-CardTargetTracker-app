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
    
    func deleteAllTransactions(forCard cardId: UUID) {
        let before = transactions.count
        transactions.removeAll { $0.cardId == cardId }
        if transactions.count != before {
            persist()
        }
    }
    
    func overwriteAll(cards newCards: [Card], transactions newTx: [Transaction]) {
        cards = newCards
        transactions = newTx
        persist()
    }
    
    @discardableResult
    func deleteAllData() -> (cards: Int, transactions: Int) {
        let removedCards = cards.count
        let removedTx = transactions.count

        if removedCards > 0 { cards.removeAll() }
        if removedTx > 0 { transactions.removeAll() }

        if removedCards > 0 || removedTx > 0 {
            persist()
        }
        return (removedCards, removedTx)
    }
    
//    @discardableResult
//    func deleteAllTransactions(forCard cardId: UUID) -> Int {
//        let before = transactions.count
//        transactions.removeAll { $0.cardId == cardId }
//        let removed = before - transactions.count
//        if removed > 0 { persist() }     // write back to storage
//        return removed
//    }

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
    
    
    @discardableResult
    func mergeImport(cards importedCards: [Card],
                     transactions importedTx: [Transaction],
                     normalizeDateToDayStart: Bool = true)
    -> (addedCards: Int, updatedCards: Int, skippedCards: Int,
        addedTx: Int, updatedTx: Int, skippedTx: Int, orphanTx: Int)
    {
        var cardIndex: [UUID: Int] = [:]
        for (i, c) in cards.enumerated() { cardIndex[c.id] = i }
        var addedCards = 0, updatedCards = 0, skippedCards = 0
        for ic in importedCards {
            if let idx = cardIndex[ic.id] {
                cards[idx] = ic
                updatedCards += 1
            } else {
                cards.append(ic)
                cardIndex[ic.id] = cards.count - 1
                addedCards += 1
            }
        }
        var txIndex: [UUID: Int] = [:]
        for (i, t) in transactions.enumerated() { txIndex[t.id] = i }

        var addedTx = 0, updatedTx = 0, skippedTx = 0, orphanTx = 0
        let cal = Calendar.current
        for it in importedTx {
            guard cardIndex[it.cardId] != nil else {
                orphanTx += 1
                continue
            }
            var txToStore = it
            if normalizeDateToDayStart {
                txToStore.date = cal.startOfDay(for: it.date)
            }

            if let idx = txIndex[txToStore.id] {
                transactions[idx] = txToStore
                updatedTx += 1
            } else {
                transactions.append(txToStore)
                txIndex[txToStore.id] = transactions.count - 1
                addedTx += 1
            }
        }
        persist()
        return (addedCards, updatedCards, skippedCards, addedTx, updatedTx, skippedTx, orphanTx)
    }
}
