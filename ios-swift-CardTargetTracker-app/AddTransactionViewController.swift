//
//  AddTransactionViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 27/10/25.
//

import UIKit

final class AddTransactionViewController: UITableViewController {
    private let amountField = UITextField()
    private let categoryControl = UISegmentedControl(items: Category.allCases.map { $0.rawValue.capitalized })
    private let noteField = UITextField()
    private let cardId: UUID

    init(cardId: UUID) {
        self.cardId = cardId
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Transaction"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        amountField.placeholder = "Amount (e.g. 25.00)"
        amountField.keyboardType = .decimalPad
        noteField.placeholder = "Note (optional)"
        categoryControl.selectedSegmentIndex = 0
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(amountField)
            amountField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                amountField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                amountField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                amountField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                amountField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                amountField.heightAnchor.constraint(equalToConstant: 44)
            ])
        case 1:
            cell.contentView.addSubview(categoryControl)
            categoryControl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                categoryControl.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                categoryControl.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                categoryControl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                categoryControl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
        default:
            cell.contentView.addSubview(noteField)
            noteField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                noteField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                noteField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                noteField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                noteField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                noteField.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        return cell
    }

    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        guard let text = amountField.text?.replacingOccurrences(of: ",", with: ""),
              let amount = Double(text), amount > 0 else {
            let alert = UIAlertController(title: "Invalid Amount", message: "Enter a valid amount.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true); return
        }
        let cents = Int((amount * 100.0).rounded())
        let category = Category.allCases[categoryControl.selectedSegmentIndex]
        let t = Transaction(cardId: cardId, amountCents: cents, category: category, date: Date(), note: noteField.text)
        TransactionManager.shared.addTransaction(t)
        dismiss(animated: true)
    }
}
