//
//  AddCardViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 24/10/25.
//

import UIKit

final class AddCardViewController: UITableViewController {

    private let nameField = UITextField()
    private let targetField = UITextField()

    private var editingCard: Card?

    init(cardToEdit: Card? = nil) {
        self.editingCard = cardToEdit
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingCard == nil ? "Add Card" : "Edit Card"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        nameField.placeholder = "Card Name"
        targetField.placeholder = "Target Amount (e.g. 1000.00)"
        targetField.keyboardType = .decimalPad

        if let c = editingCard {
            nameField.text = c.name
            targetField.text = String(format: "%.2f", Double(c.targetCents) / 100.0)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(nameField)
            nameField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                nameField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                nameField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                nameField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                nameField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                nameField.heightAnchor.constraint(equalToConstant: 44)
            ])
        default:
            cell.contentView.addSubview(targetField)
            targetField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                targetField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                targetField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                targetField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                targetField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                targetField.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        return cell
    }

    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let text = targetField.text?.replacingOccurrences(of: ",", with: ""),
              let amount = Double(text), amount > 0 else {
            let alert = UIAlertController(title: "Invalid Input", message: "Please enter name and target.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let cents = Int((amount * 100.0).rounded())

        if var editingCard = editingCard {
            editingCard.name = name
            editingCard.targetCents = cents
            TransactionManager.shared.updateCard(editingCard)
        } else {
            let newCard = Card(name: name,
                               targetCents: cents,
                               cycle: .monthly(startDay: 1),
                               notifyDaysBefore: 3,
                               dailyReminderTime: nil)
            TransactionManager.shared.addCard(newCard)
        }
        dismiss(animated: true)
    }
}
