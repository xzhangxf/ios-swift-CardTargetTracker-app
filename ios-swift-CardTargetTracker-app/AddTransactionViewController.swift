//
//  AddTransactionViewController.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 27/10/25.
//

import UIKit

class AddTransactionViewController: UITableViewController {

    // MARK: - Init
    private let cardId: UUID
    private var editingTransaction: Transaction?

    init(cardId: UUID, editingTransaction: Transaction? = nil) {
        self.cardId = cardId
        self.editingTransaction = editingTransaction
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Model State
    private var amountCents: Int = 0
    private var selectedCategory: Category = Category.allCases.first ?? .others
    private var selectedDate: Date = Date()
    private var noteText: String?

    private let categories = Category.allCases

    // MARK: - UI
    private let amountField = UITextField()
    private let noteField = UITextField()
    private let dateButton = UIButton(type: .system)

    // Horizontal scroller
    private lazy var categoryLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumInteritemSpacing = 8
        l.minimumLineSpacing = 8
        l.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return l
    }()
    private lazy var categoryCollection = UICollectionView(frame: .zero, collectionViewLayout: categoryLayout)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingTransaction == nil ? "Add Transaction" : "Edit Transaction"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(close)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(save)
        )

        // Preload values if editing
        if let t = editingTransaction {
            amountCents = t.amountCents
            selectedCategory = t.category
            selectedDate = t.date
            noteText = t.note
        }

        // Amount
        amountField.placeholder = "Amount (e.g. 25.00)"
        amountField.keyboardType = .decimalPad
        amountField.clearButtonMode = .whileEditing
        if amountCents > 0 {
            amountField.text = String(format: "%.2f", Double(amountCents) / 100.0)
        }
        amountField.inputAccessoryView = makeToolbar()

        // Date button (shows chosen date)
        styleDateButton()
        updateDateButtonTitle()

        // Note
        noteField.placeholder = "Note (optional)"
        noteField.clearButtonMode = .whileEditing
        noteField.text = noteText
        noteField.inputAccessoryView = makeToolbar()

        // Category scroller
        categoryCollection.backgroundColor = .clear
        categoryCollection.alwaysBounceHorizontal = true
        categoryCollection.showsHorizontalScrollIndicator = false
        categoryCollection.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        categoryCollection.register(CategoryPillCell.self, forCellWithReuseIdentifier: "pill")
        categoryCollection.dataSource = self
        categoryCollection.delegate = self

        tableView.keyboardDismissMode = .onDrag
    }

    // MARK: - Table
    override func numberOfSections(in tableView: UITableView) -> Int { 4 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Amount"
        case 1: return "Type"
        case 2: return "Date"
        default: return "Note"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0: // Amount
            embed(amountField, in: cell)
        case 1: // Category scroller
            embed(categoryCollection, in: cell, height: 52)
            // Preselect current category (after first layout pass)
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                      let idx = self.categories.firstIndex(of: self.selectedCategory) else { return }
                let ip = IndexPath(item: idx, section: 0)
                self.categoryCollection.selectItem(at: ip, animated: false, scrollPosition: .centeredHorizontally)
            }
        case 2: // Date button
            embed(dateButton, in: cell, height: 44)
        default: // Note
            embed(noteField, in: cell)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 { presentDatePicker() }
    }

    // MARK: - Actions
    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        // Parse amount to cents
        let cleaned = (amountField.text ?? "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(cleaned), amount > 0 else {
            showAlert("Invalid amount", "Please enter a valid amount.")
            return
        }
        amountCents = Int((amount * 100).rounded())
        noteText = noteField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if var t = editingTransaction {
            // Update existing
            t.amountCents = amountCents
            t.category = selectedCategory
            t.date = selectedDate
            t.note = noteText
            TransactionManager.shared.updateTransaction(t)
        } else {
            // Create new
            let tx = Transaction(
                id: UUID(),
                cardId: cardId,
                amountCents: amountCents,
                category: selectedCategory,
                date: selectedDate,
                note: noteText
            )
            TransactionManager.shared.addTransaction(tx)
        }
        dismiss(animated: true)
    }

    private func presentDatePicker() {
        let picker = DatePickerSheetViewController()
        picker.initialDate = selectedDate
        picker.modalPresentationStyle = .pageSheet
        picker.onPicked = { [weak self] date in
            self?.selectedDate = date
            self?.updateDateButtonTitle()
        }
        present(picker, animated: true)
    }

    // MARK: - Helpers
    private func styleDateButton() {
        dateButton.configuration = .plain()
        dateButton.contentHorizontalAlignment = .leading
        dateButton.titleLabel?.font = .systemFont(ofSize: 17)
        dateButton.addTarget(self, action: #selector(onDateButton), for: .touchUpInside)
    }
    @objc private func onDateButton() { presentDatePicker() }

    private func updateDateButtonTitle() {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        dateButton.setTitle(df.string(from: selectedDate), for: .normal)
    }

    private func embed(_ viewToEmbed: UIView, in cell: UITableViewCell, height: CGFloat? = nil) {
        viewToEmbed.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(viewToEmbed)
        var cs = [
            viewToEmbed.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            viewToEmbed.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            viewToEmbed.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            viewToEmbed.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6)
        ]
        if let h = height {
            cs.append(viewToEmbed.heightAnchor.constraint(equalToConstant: h))
        }
        NSLayoutConstraint.activate(cs)
    }

    private func showAlert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func makeToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        ]
        tb.sizeToFit()
        return tb
    }
    @objc private func dismissKeyboard() { view.endEditing(true) }
}

// MARK: - Category Scroller
extension AddTransactionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "pill", for: indexPath) as! CategoryPillCell
        cell.configure(text: categories[indexPath.item].rawValue.capitalized)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategory = categories[indexPath.item]
    }
}

// MARK: - Pill Cell
private final class CategoryPillCell: UICollectionViewCell {
    private let label = UILabel()
    override var isSelected: Bool { didSet { applyStyle() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemFill
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true

        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        applyStyle()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(text: String) { label.text = text }

    private func applyStyle() {
        if isSelected {
            contentView.backgroundColor = .systemBlue
            label.textColor = .white
        } else {
            contentView.backgroundColor = .secondarySystemFill
            label.textColor = .label
        }
    }
}
