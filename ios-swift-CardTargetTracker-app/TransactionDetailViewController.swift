//
//  TransactionDetailViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 28/10/25.
//

import UIKit

class TransactionDetailViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    private var transaction: Transaction

    // UI
    private let amountField = UITextField()
    private let categoryField = UITextField()
    private let datePicker = UIDatePicker()
    private let noteField = UITextField()

    private let categoryPicker = UIPickerView()
    private let categories = Category.allCases

    init(transaction: Transaction) {
        self.transaction = transaction
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transaction"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(save)
        )

        // Amount
        amountField.placeholder = "Amount"
        amountField.keyboardType = .decimalPad
        amountField.clearButtonMode = .whileEditing
        amountField.text = amountString(fromCents: transaction.amountCents)
        amountField.delegate = self

        // Category
        categoryField.placeholder = "Category"
        categoryField.inputView = categoryPicker
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        if let idx = categories.firstIndex(of: transaction.category) {
            categoryPicker.selectRow(idx, inComponent: 0, animated: false)
            categoryField.text = categories[idx].rawValue.capitalized
        }

        // Date
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .inline
        datePicker.date = transaction.date

        // Note
        noteField.placeholder = "Note (optional)"
        noteField.text = transaction.note
        noteField.clearButtonMode = .whileEditing
    }

    // MARK: - Table
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2      // amount, category
        case 1: return 1      // date
        default: return 1     // note
        }
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Basics"
        case 1: return "Date"
        default: return "Note"
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.contentView.addSubview(amountField)
            pin(amountField, to: cell)
        case (0, 1):
            cell.contentView.addSubview(categoryField)
            pin(categoryField, to: cell)
        case (1, 0):
            cell.contentView.addSubview(datePicker)
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                datePicker.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                datePicker.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                datePicker.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                datePicker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4)
            ])
        default:
            cell.contentView.addSubview(noteField)
            pin(noteField, to: cell)
        }
        return cell
    }

    private func pin(_ view: UIView, to cell: UITableViewCell) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            view.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            view.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        categories.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categories[row].rawValue.capitalized
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryField.text = categories[row].rawValue.capitalized
        categoryField.resignFirstResponder()
    }

    // MARK: - Save
    @objc private func save() {
        // Amount -> cents
        let cleaned = (amountField.text ?? "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let amount = Double(cleaned), amount > 0 else {
            alert("Invalid amount", "Please enter a valid amount.")
            return
        }
        let cents = Int((amount * 100.0).rounded())

        // Category
        let catIdx = categoryPicker.selectedRow(inComponent: 0)
        let cat = categories[catIdx]

        // Build updated model
        var updated = transaction
        updated.amountCents = cents
        updated.category = cat
        updated.date = datePicker.date
        updated.note = noteField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        TransactionManager.shared.updateTransaction(updated)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Helpers
    private func amountString(fromCents cents: Int) -> String {
        // Render as plain number (easier to edit). If you prefer “$1,234.56”, plug in CurrencyFormatter here.
        String(format: "%.2f", Double(cents) / 100.0)
    }

    private func alert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // Dismiss pickers when tapping return on text fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}
